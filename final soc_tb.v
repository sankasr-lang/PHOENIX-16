`timescale 1ns/1ps

module tb;

reg clk = 0;
reg sys_rst = 1;

reg [15:0] din = 0;
wire [15:0] dout;

wire tx;
reg rx = 1;

reg [7:0] gpio_in = 8'h3C;     
wire [7:0] gpio_out;

wire pwmout;

// SPI
wire MOSI;
wire SCLK;
wire CS;
wire MISO;

// 7-segment
wire [6:0] seg;
wire [3:0] an;

top dut(
    .clk(clk),
    .sys_rst(sys_rst),
    .din(din),
    .dout(dout),
    .tx(tx),
    .rx(rx),
    .gpio_out(gpio_out),
    .gpio_in(gpio_in),
    .pwmout(pwmout),

    .MISO(MISO),
    .MOSI(MOSI),
    .SCLK(SCLK),
    .CS(CS),
    .seg(seg),
    .an(an)
 
);

/////////////////////////////////////////////////
// Clock
/////////////////////////////////////////////////

always #5 clk = ~clk;

/////////////////////////////////////////////////
// Reset
/////////////////////////////////////////////////

initial begin
    sys_rst = 1;

    repeat(5) @(posedge clk);

    sys_rst = 0;
end

localparam CLKS_PER_BIT = 4;
localparam UART_TEST_BYTE = 8'h55;

task automatic uart_send_byte(input [7:0] data);
    integer i;
    begin
        rx = 1'b0;                          // start bit
        repeat (CLKS_PER_BIT) @(posedge clk);
        for (i = 0; i < 8; i = i + 1) begin
            rx = data[i];                   // LSB first
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
        rx = 1'b1;                          // stop bit
        repeat (CLKS_PER_BIT) @(posedge clk);
    end
endtask

initial begin
    @(negedge sys_rst);
    repeat (5) @(posedge clk);
    uart_send_byte(UART_TEST_BYTE);
end
reg       ext_spi_active = 1'b0;
reg       ext_mosi       = 1'b0;
reg       ext_sclk       = 1'b0;
reg       ext_cs         = 1'b1;
reg [7:0] rx_from_slave  = 8'h00;

localparam EXT_TX_BYTE = 8'hA5;  // byte the tb sends to test SPI Slave RX

assign MOSI = ext_spi_active ? ext_mosi : 1'bz;
assign SCLK = ext_spi_active ? ext_sclk : 1'bz;
assign CS   = ext_spi_active ? ext_cs   : 1'bz;
assign MISO = ext_spi_active ? 1'bz     : MOSI;

task automatic spi_ext_transfer(input [7:0] tx_byte, output [7:0] rx_byte);
    integer i;
    begin
        ext_spi_active = 1'b1;
        ext_cs   = 1'b0;
        ext_sclk = 1'b0;
        #20;
        for (i = 7; i >= 0; i = i - 1) begin
            ext_mosi = tx_byte[i];
            #20;
            ext_sclk = 1'b1;
            rx_byte[i] = MISO;
            #20;
            ext_sclk = 1'b0;
        end
        #20;
        ext_cs = 1'b1;
        ext_spi_active = 1'b0;
    end
endtask


initial begin
    wait (dut.CTRL_REG[3:0] == 4'd8 && dut.state == 2);
    repeat (2) @(posedge clk);   // let spi_slave_tx_data settle
    spi_ext_transfer(EXT_TX_BYTE, rx_from_slave);
end

/////////////////////////////////////////////////
// SPI Monitor
/////////////////////////////////////////////////

always @(posedge SCLK)
begin
    if(!CS)
    begin
        $display("TIME=%0t MOSI=%b MISO=%b",
                  $time,MOSI,MISO);
    end
end

/////////////////////////////////////////////////
// SPI transaction complete
/////////////////////////////////////////////////

always @(posedge dut.spi_done)
begin
    $display("--------------------------------");
    $display("SPI MASTER TX = %h",dut.spi_tx_data);
    $display("SPI MASTER RX = %h",dut.spi_rx_data);
    $display("--------------------------------");
end

always @(posedge dut.spi_slave_done)
begin
    $display("--------------------------------");
    $display("SPI SLAVE RX = %h",dut.spi_slave_rx_data);
    $display("--------------------------------");
end

/////////////////////////////////////////////////
// 7 segment monitor
/////////////////////////////////////////////////

always @(seg or an)
begin
    $display("TIME=%0t an=%b seg=%b",
              $time,an,seg);
end

/////////////////////////////////////////////////
// Register monitor
/////////////////////////////////////////////////

always @(posedge clk)
begin
    if(dut.state==2)
    begin
        $display("PC=%d CTRL=%d",
                  dut.PC,
                  dut.CTRL_REG[3:0]);
    end
end

/////////////////////////////////////////////////
// Finish simulation

/////////////////////////////////////////////////

initial begin

    #20000;

    $display("================================");
    $display("UART RX   (R2)         = %h   (expect 0055)", dut.GPR[2]);
    $display("GPIO OUT               = %h   (expect a5)",   gpio_out);
    $display("GPIO IN   (R4)         = %h   (expect 003c)", dut.GPR[4]);
    $display("TIMER done             = %b",                 dut.timerdone);
    $display("PWM period/duty        = %d / %d",             dut.pwmperiod, dut.pwmduty);
    $display("SPI MASTER (R9)        = %h   (expect 9999)", dut.GPR[9]);
    $display("SPI SLAVE TX read back = %h   (expect 77)",   rx_from_slave);
    $display("SPI SLAVE RX (R11)     = %h   (expect 00a5)", dut.GPR[11]);
    $display("SEG7 VALUE             = %h   (expect 1234)", dut.seg7_value);
    $display("================================");

    $stop;

end

endmodule