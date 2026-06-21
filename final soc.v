`timescale 1ns / 1ps

// ─── Opcodes ─────────────────────────────────────────────────────────────────
`define movsgpr     6'b000000
`define mov         6'b000001
`define add         6'b000010
`define sub         6'b000011
`define mul         6'b000100
`define ror         6'b000101
`define rand        6'b000110
`define rxor        6'b000111
`define rxnor       6'b001000
`define rnand       6'b001001
`define rnor        6'b001010
`define rnot        6'b001011
`define storereg    6'b001101
`define storedin    6'b001110
`define senddout    6'b001111 
`define sendreg     6'b010001
`define jump        6'b010010
`define jcarry      6'b010011
`define jnocarry    6'b010100
`define jsign       6'b010101
`define jnosign     6'b010110
`define jzero       6'b010111
`define jnozero     6'b011000
`define joverflow   6'b011001
`define jnooverflow 6'b011010
`define halt        6'b011011
`define setctrl     6'b011100
`define select      6'b011101
`define call        6'b011110
`define ret         6'b011111
`define nop         6'b100000
`define push        6'b100001
`define pop         6'b100010
`define shl         6'b100011
`define shr         6'b100100
`define sar         6'b100101
`define cmp         6'b100110
`define inc         6'b101000
`define dec         6'b101001
`define rorr        6'b101010
`define roll        6'b101011
`define clr         6'b101100
//////peripherals
`define PERI_UART_TX  4'd1
`define PERI_UART_RX  4'd2
`define PERI_GPIO_OUT 4'd3
`define PERI_GPIO_IN  4'd4
`define PERI_TIMER    4'd5
`define PERI_PWM      4'd6
`define PERI_SPI      4'd7
`define PERI_SPI_SLAVE_TX 4'd8   // load the byte to send back when polled
`define PERI_SPI_SLAVE_RX 4'd9   // non-blocking: take received byte if ready
`define PERI_SEG7         4'd10

module top(
    input             clk, sys_rst,
    input      [15:0] din,
    output reg [15:0] dout,
    output wire        tx,
    input              rx,
    output reg [7:0]   gpio_out,
    input      [7:0]   gpio_in,
    output wire        pwmout,
  
       inout              MISO,
       inout              MOSI,
       inout              SCLK,
          inout              CS,
       output wire [6:0]  seg,
       output wire [3:0]  an
    
);

reg [5:0] oper_type;
reg [4:0] rdst;
reg [4:0] rsrc1;
reg [4:0] rsrc2;
reg       imm_mode;
reg [15:0] isrc;
reg [31:0] inst_mem [63:0];
reg [15:0] data_mem [63:0];
reg [31:0] IR_fetch;
reg [31:0] IR_exec;
reg [15:0] GPR [31:0];
reg [15:0] SGPR;
reg [31:0] mul_res;
reg [16:0] temp_sum;
reg [15:0] SP;
reg [15:0] CTRL_REG;
reg sign, zero, overflow, carry;
reg jmp_flag, stop;
reg [15:0] target_pc;
reg [31:0] mul_temp;
//peripheral registers
reg [7:0]  UART_REG;
reg        uart_start, cu_ack;
wire       tx_done, uart_busy;
wire [7:0] uart_rx_data;
wire       irq;

reg         timerenable;
reg         timerdir;
reg  [15:0] timertarget;
reg  [15:0] timerload;
wire [15:0] timercount;
wire        timerdone;

reg pwmenable;
reg [7:0] pwmperiod;
reg [7:0] pwmduty;

reg        spi_enable;
reg [7:0]  spi_tx_data;
wire [7:0] spi_rx_data;
wire       spi_busy;
wire       spi_done;
reg  [7:0] spi_slave_tx_data;
wire [7:0] spi_slave_rx_data;   // raw output straight from spi_slave module
wire       spi_slave_done;      // raw 1-cycle pulse straight from spi_slave module
reg  [7:0] spi_slave_rx_byte;   // latched copy - survives until consumed
reg        spi_slave_rx_valid;  // sticky "a byte is waiting" flag
reg [15:0] seg7_value;


wire mosi_m, sclk_m, cs_m;   // master's driven outputs (internal)
wire miso_s;                  // slave's driven output   (internal)
// slave keep listening in the background while your code does other work.
wire spi_mode_is_slave;
assign spi_mode_is_slave =
       (CTRL_REG[3:0] == `PERI_SPI_SLAVE_TX) ||
       (CTRL_REG[3:0] == `PERI_SPI_SLAVE_RX);

wire mosi_m, sclk_m, cs_m;   // master's driven outputs (internal)
wire miso_s;                  // slave's driven output   (internal)

assign MOSI = spi_mode_is_slave ? 1'bz : mosi_m;
assign SCLK = spi_mode_is_slave ? 1'bz : sclk_m;
assign CS   = spi_mode_is_slave ? 1'bz : cs_m;
assign MISO = spi_mode_is_slave ? miso_s : 1'bz;

wire miso_in_m = MISO;   // master reads external slave device on MISO
wire mosi_in_s = MOSI;   // our slave reads external master's MOSI
wire sclk_in_s = SCLK;   // our slave reads external master's SCLK
wire cs_in_s   = CS;     // our slave reads external master's CS

assign MOSI = spi_mode_is_slave ? 1'bz : mosi_m;
assign SCLK = spi_mode_is_slave ? 1'bz : sclk_m;
assign CS   = spi_mode_is_slave ? 1'bz : cs_m;
assign MISO = spi_mode_is_slave ? miso_s : 1'bz;

wire miso_in_m = MISO;   // master reads external slave device on MISO
wire mosi_in_s = MOSI;   // our slave reads external master's MOSI
wire sclk_in_s = SCLK;   // our slave reads external master's SCLK
wire cs_in_s   = CS;     // our slave reads external master's 



always @(*) begin
    if (oper_type==`mul) begin
        
    
    if (imm_mode)
        mul_temp = GPR[rsrc1] * isrc;
    else
        mul_temp = GPR[rsrc1] * GPR[rsrc2];
end
end
///peripherals 

uart_tx U1(.clk(clk),.rst(sys_rst),.tx_start(uart_start),
           .data_in(UART_REG),
           .tx(tx),.tx_done(tx_done),.busy(uart_busy));

uart_rx U2(.clk(clk),.rst(sys_rst),.rx(rx),
           .data_out(uart_rx_data),
           .cpu_ack(cu_ack),.data_valid(irq));

timer U3(.clk(clk),.rst(sys_rst),.enable(timerenable),.dir(timerdir),
         .target_value(timertarget),.load_value(timerload),
         .timer_value(timercount),.done(timerdone));

pwm P1(.clk(clk),.rst(sys_rst),.enable(pwmenable),.period(pwmperiod),
       .duty(pwmduty),.pwm_out(pwmout));

   spi_master S1(.clk(clk),.rst(sys_rst),.enable(spi_enable),
                .spi_tx_data(spi_tx_data),.MISO(miso_in_m),
                .MOSI(mosi_m),.SCLK(sclk_m),.CS(cs_m),
                 .spi_rx_data(spi_rx_data),.spi_busy(spi_busy),.spi_done(spi_done));
spi_slave SS1(.clk(clk),.rst(sys_rst),
              .SCLK(sclk_in_s),.CS(cs_in_s),.MOSI(mosi_in_s),
              .MISO(miso_s),
              .tx_data(spi_slave_tx_data),.rx_data(spi_slave_rx_data),
              .done(spi_slave_done));

seg7_driver SEG1(.clk(clk),.rst(sys_rst),.value(seg7_value),
                  .seg(seg),.an(an));
 assign peripheral_busy =
       (CTRL_REG[3:0] == `PERI_UART_TX && uart_busy)  ||
       (CTRL_REG[3:0] == `PERI_UART_RX && !irq)        ||
       (CTRL_REG[3:0] == `PERI_TIMER   && !timerdone)  ||
       (CTRL_REG[3:0] == `PERI_SPI     && !spi_done) ;
      
// ─── FSM States ──────────────────────────────────────────────────────────────
parameter IDLE      = 0,
          RUN        = 1,
          BUSY_WAIT  = 2,
          HALT       = 3;

reg [2:0] state = IDLE, next_state = IDLE;
integer   PC = 0;

reg [4:0]  rdst_latch;
reg [15:0] ctrl_data;

initial $readmemb("inst_data.mem", inst_mem);
//////for busy wait 
wire peripheral_busy;
assign peripheral_busy =
    (CTRL_REG[3:0] == `PERI_UART_TX && uart_busy)  ||
    (CTRL_REG[3:0] == `PERI_UART_RX && !irq)        ||
    (CTRL_REG[3:0] == `PERI_TIMER   && !timerdone)  ||
    (CTRL_REG[3:0] == `PERI_SPI     && !spi_done);
///stall
wire branch_taken;
assign branch_taken =
       (oper_type == `jump) ||
       ((oper_type == `jcarry)      && carry) ||
       ((oper_type == `jnocarry)    && ~carry) ||
       ((oper_type == `jsign)       && sign) ||
       ((oper_type == `jnosign)     && ~sign) ||
       ((oper_type == `jzero)       && zero) ||
       ((oper_type == `jnozero)     && ~zero) ||
       ((oper_type == `joverflow)   && overflow) ||
       ((oper_type == `jnooverflow) && ~overflow) ||  (oper_type==`call) ||
       (oper_type==`ret );

wire stall = (state == BUSY_WAIT);

always @(*) begin
    imm_mode = IR_exec[0];
    if (IR_exec[0] == 1'b0) begin
        oper_type = IR_exec[31:26];
        rdst   = IR_exec[25:21];
        rsrc1  = IR_exec[20:16];
        rsrc2  = IR_exec[15:11];
    end else begin
        oper_type = IR_exec[31:26];
        rdst   = IR_exec[25:22];
        rsrc1  = {1'b0, IR_exec[21:17]};
        isrc   = IR_exec[16:1];
    end
end
always @(posedge clk or posedge sys_rst) begin
    if (sys_rst) begin
        spi_slave_rx_byte  <= 8'd0;
        spi_slave_rx_valid <= 1'b0;
    end else if (spi_mode_is_slave && spi_slave_done) begin
        spi_slave_rx_byte  <= spi_slave_rx_data;
        spi_slave_rx_valid <= 1'b1;
    end else if (state == BUSY_WAIT && CTRL_REG[3:0] == `PERI_SPI_SLAVE_RX) begin
        spi_slave_rx_valid <= 1'b0;   // consumed by the RX select below
    end
end
always @(*) begin
    target_pc = PC;
    if(oper_type == `jump)
      target_pc = isrc;
    else if(oper_type == `jcarry && carry)
      target_pc = isrc;
    else if(oper_type == `jnocarry && ~carry)
      target_pc = isrc;
    else if(oper_type == `jsign && sign)
      target_pc = isrc;
    else if(oper_type == `jnosign && ~sign)
      target_pc = isrc;
    else if(oper_type == `jzero && zero)
      target_pc = isrc;
    else if(oper_type == `jnozero && ~zero)
      target_pc = isrc;
    else if(oper_type == `joverflow && overflow)
      target_pc = isrc;
    else if(oper_type == `jnooverflow && ~overflow)
      target_pc = isrc;
    else if(oper_type == `call)
      target_pc = isrc;
      else if(oper_type == `ret)
      target_pc = data_mem[SP + 1];
end
always @(posedge clk or posedge sys_rst)
    state <= sys_rst ? IDLE : next_state;

//  Next-State Logic

always @(*) begin
    case(state)
        IDLE : next_state = RUN;

        RUN: begin
            if (oper_type == `select)
                next_state = BUSY_WAIT;
            else if (oper_type == `halt)
                next_state = HALT;
            else
                next_state = RUN;
        end

        BUSY_WAIT: next_state = peripheral_busy ? BUSY_WAIT : RUN;

        HALT: next_state = HALT;

        default: next_state = HALT;
    endcase
end

//  Datapath
always @(posedge clk or posedge sys_rst) begin
    if (sys_rst) begin
        PC <= 0; IR_fetch <= 0; IR_exec <= 0;
        jmp_flag <= 0; stop <= 0;
        uart_start <= 0; cu_ack <= 0;
        UART_REG <= 0; CTRL_REG <= 0; ctrl_data <= 0;
        gpio_out <= 0;
        timerenable <= 0; timerdir <= 0;
        timertarget <= 0; timerload <= 0;
        pwmenable <= 0; pwmperiod <= 0; pwmduty <= 0;
        spi_enable <= 0; spi_tx_data <= 0;
        sign <= 0; zero <= 0; overflow <= 0; carry <= 0; SP <= 63;
         spi_slave_tx_data <= 0;
          seg7_value        <= 0;
    end else begin
        uart_start <= 0;
        cu_ack     <= 0;

        case(state)

        IDLE: begin
            PC       <= 0;
            IR_fetch <= inst_mem[0];
            IR_exec  <= 0;
        end

        RUN: begin
            jmp_flag <= 0; stop <= 0;

            case(oper_type)
                `movsgpr : GPR[rdst] <= SGPR;
                `mov     : GPR[rdst] <= imm_mode ? isrc : GPR[rsrc1];
                
             `add: begin
    GPR[rdst] <= imm_mode ? GPR[rsrc1]+isrc :
                            GPR[rsrc1]+GPR[rsrc2];

    carry <= imm_mode ?
             ({1'b0,GPR[rsrc1]}+{1'b0,isrc}>17'hFFFF) :
             ({1'b0,GPR[rsrc1]}+{1'b0,GPR[rsrc2]}>17'hFFFF);

    sign <= imm_mode ?
            ((GPR[rsrc1]+isrc)>=16'h8000) :
            ((GPR[rsrc1]+GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]+isrc)==0) :
            ((GPR[rsrc1]+GPR[rsrc2])==0);

    overflow <= imm_mode ?
       (~GPR[rsrc1][15]&~isrc[15]&(GPR[rsrc1]+isrc>=16'h8000))|
       ( GPR[rsrc1][15]& isrc[15]&(GPR[rsrc1]+isrc<16'h8000))
    :
       (~GPR[rsrc1][15]&~GPR[rsrc2][15]&(GPR[rsrc1]+GPR[rsrc2]>=16'h8000))|
       ( GPR[rsrc1][15]& GPR[rsrc2][15]&(GPR[rsrc1]+GPR[rsrc2]<16'h8000));
end

`sub: begin
    GPR[rdst] <= imm_mode ? GPR[rsrc1]-isrc :
                            GPR[rsrc1]-GPR[rsrc2];

    carry <= imm_mode ?
             (GPR[rsrc1]<isrc) :
             (GPR[rsrc1]<GPR[rsrc2]);

    sign <= imm_mode ?
            ((GPR[rsrc1]-isrc)>=16'h8000) :
            ((GPR[rsrc1]-GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]-isrc)==0) :
            ((GPR[rsrc1]-GPR[rsrc2])==0);

    overflow <= imm_mode ?
       (~GPR[rsrc1][15]&isrc[15]&((GPR[rsrc1]-isrc)>=16'h8000))|
       ( GPR[rsrc1][15]&~isrc[15]&((GPR[rsrc1]-isrc)<16'h8000))
    :
       (~GPR[rsrc1][15]&GPR[rsrc2][15]&((GPR[rsrc1]-GPR[rsrc2])>=16'h8000))|
       ( GPR[rsrc1][15]&~GPR[rsrc2][15]&((GPR[rsrc1]-GPR[rsrc2])<16'h8000));
end
`mul: begin
   

    GPR[rdst] <= mul_temp[15:0];
    SGPR      <= mul_temp[31:16];

    sign      <= mul_temp[31];
    zero      <= (mul_temp == 0);
    carry     <= 0;
    overflow  <= |mul_temp[31:16];
end

`ror: begin
    GPR[rdst] <= imm_mode ? (GPR[rsrc1]|isrc) :
                        (GPR[rsrc1]|GPR[rsrc2]);

    sign <= imm_mode ?
            ((GPR[rsrc1]|isrc)>=16'h8000) :
            ((GPR[rsrc1]|GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]|isrc)==0) :
            ((GPR[rsrc1]|GPR[rsrc2])==0);

    carry <= 0;
    overflow <= 0;
end

`rand: begin
    GPR[rdst] <= imm_mode ? GPR[rsrc1]&isrc :
                            GPR[rsrc1]&GPR[rsrc2];

    sign <= imm_mode ?
            ((GPR[rsrc1]&isrc)>=16'h8000) :
            ((GPR[rsrc1]&GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]&isrc)==0) :
            ((GPR[rsrc1]&GPR[rsrc2])==0);

    carry <= 0;
    overflow <= 0;
end
`rxor: begin
    GPR[rdst] <= imm_mode ? GPR[rsrc1]^isrc :
                            GPR[rsrc1]^GPR[rsrc2];

    sign <= imm_mode ?
            ((GPR[rsrc1]^isrc)>=16'h8000) :
            ((GPR[rsrc1]^GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]^isrc)==0) :
            ((GPR[rsrc1]^GPR[rsrc2])==0);

    carry <= 0;
    overflow <= 0;
end

`rxnor: begin
   GPR[rdst] <= imm_mode ? GPR[rsrc1]~^isrc :
                            GPR[rsrc1]~^GPR[rsrc2];

    sign <= imm_mode ?
            ((GPR[rsrc1]~^isrc)>=16'h8000) :
            ((GPR[rsrc1]~^GPR[rsrc2])>=16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1]~^isrc)==0) :
            ((GPR[rsrc1]~^GPR[rsrc2])==0);

    carry <= 0;
    overflow <= 0;
end

`rnand: begin
  

     GPR[rdst] <= imm_mode ?  ~(GPR[rsrc1]&isrc) :
                         ~(GPR[rsrc1]&GPR[rsrc2]);
    sign <= imm_mode ?
            ((~(GPR[rsrc1]&isrc))>=16'h8000) :
            ((~(GPR[rsrc1]&GPR[rsrc2]))>=16'h8000);

    zero <= imm_mode ?
            ((~(GPR[rsrc1]&isrc))==0) :
            ((~(GPR[rsrc1]&GPR[rsrc2]))==0);

    carry <= 0;
    overflow <= 0;
end

`rnor: begin
    
     GPR[rdst] <= imm_mode ?  ~(GPR[rsrc1]|isrc) :
                         ~(GPR[rsrc1]|GPR[rsrc2]);
    sign <= imm_mode ?
            ((~(GPR[rsrc1]|isrc))>=16'h8000) :
            ((~(GPR[rsrc1]|GPR[rsrc2]))>=16'h8000);

    zero <= imm_mode ?
            ((~(GPR[rsrc1]|isrc))==0) :
            ((~(GPR[rsrc1]|GPR[rsrc2]))==0);

    carry <= 0;
    overflow <= 0;
end

`rnot: begin
     GPR[rdst] <= imm_mode ? ~isrc : ~GPR[rsrc1];

     sign <= imm_mode ?
            (~isrc>=16'h8000) :
            (~GPR[rsrc1]>=16'h8000);

    zero <= imm_mode ?
            (~isrc==0) :
            (~GPR[rsrc1]==0);

    carry <= 0;
    overflow <= 0;
end

                `storedin : data_mem[isrc] <= din;
                `storereg : data_mem[isrc] <= GPR[rsrc1];
                `senddout : dout           <= data_mem[isrc];
                `sendreg  : GPR[rdst]      <= data_mem[isrc];

                `jump       : jmp_flag <= 1;
                `jcarry     : jmp_flag <= carry;
                `jnocarry   : jmp_flag <= ~carry;
                `jsign      : jmp_flag <= sign;
                `jnosign    : jmp_flag <= ~sign;
                `jzero      : jmp_flag <= zero;
                `jnozero    : jmp_flag <= ~zero;
                `joverflow  : jmp_flag <= overflow;
                `jnooverflow: jmp_flag <= ~overflow;

                `shl: begin
    GPR[rsrc1] <= GPR[rsrc1]<<isrc;

    carry <= GPR[rsrc1][16-isrc];
    sign <= ((GPR[rsrc1]<<isrc)>=16'h8000);
    zero <= ((GPR[rsrc1]<<isrc)==0);
    overflow <= 0;
end
                `shr: begin
    GPR[rsrc1] <= GPR[rsrc1] >> isrc;

    carry <= GPR[rsrc1][isrc-1];
    sign <= ((GPR[rsrc1] >> isrc) >= 16'h8000);
    zero <= ((GPR[rsrc1] >> isrc) == 0);
    overflow <= 0;
end
                `sar: begin
    GPR[rsrc1] <= $signed(GPR[rsrc1]) >>> isrc;

    carry <= GPR[rsrc1][isrc-1 ];
    sign <= ((GPR[rsrc1] >>> isrc) >= 16'h8000);
    zero <= ((GPR[rsrc1] >>> isrc) == 0);
    overflow <= 0;
end
                `cmp: begin
    carry <= imm_mode ?
             (GPR[rsrc1] < isrc) :
             (GPR[rsrc1] < GPR[rsrc2]);

    sign <= imm_mode ?
            ((GPR[rsrc1] - isrc) >= 16'h8000) :
            ((GPR[rsrc1] - GPR[rsrc2]) >= 16'h8000);

    zero <= imm_mode ?
            ((GPR[rsrc1] - isrc) == 16'd0) :
            ((GPR[rsrc1] - GPR[rsrc2]) == 16'd0);

    overflow <= imm_mode ?
       (~GPR[rsrc1][15] &  isrc[15] &
        ((GPR[rsrc1]-isrc) >= 16'h8000)) |
       ( GPR[rsrc1][15] & ~isrc[15] &
        ((GPR[rsrc1]-isrc) < 16'h8000))
    :
       (~GPR[rsrc1][15] &  GPR[rsrc2][15] &
        ((GPR[rsrc1]-GPR[rsrc2]) >= 16'h8000)) |
       ( GPR[rsrc1][15] & ~GPR[rsrc2][15] &
        ((GPR[rsrc1]-GPR[rsrc2]) < 16'h8000));
end
                `inc: begin
    GPR[rsrc1] <= GPR[rsrc1]+1'b1;

    carry <= (GPR[rsrc1]==16'hFFFF);
    sign <= ((GPR[rsrc1]+1)>=16'h8000);
    zero <= ((GPR[rsrc1]+1)==0);
    overflow <= (GPR[rsrc1]==16'h7FFF);
end
                `dec: begin
    GPR[rsrc1] <= GPR[rsrc1]-1'b1;

    carry <= (GPR[rsrc1]==0);
    sign <= ((GPR[rsrc1]-1)>=16'h8000);
    zero <= ((GPR[rsrc1]-1)==0);
    overflow <= (GPR[rsrc1]==16'h8000);
end
                `rorr: GPR[rsrc1] <= {GPR[rsrc1][0], GPR[rsrc1][15:1]};
                `roll: GPR[rsrc1] <= {GPR[rsrc1][14:0], GPR[rsrc1][15]};
                `clr: begin
    GPR[rsrc1] <= 0;

    carry <= 0;
    sign <= 0;
    zero <= 1;
    overflow <= 0;
end
                `nop : ;
                `setctrl: CTRL_REG <= isrc;

                `select: begin
                    rdst_latch <= rsrc1;
                    ctrl_data  <= GPR[rsrc1];
                end

                `call: begin
                    data_mem[SP] <= PC ;
                    SP           <= SP - 1;
                    jmp_flag     <= 1'b1;
                end
                `ret: SP <= SP + 1;
                `push: begin
                    data_mem[SP] <= GPR[rsrc1];
                    SP           <= SP - 1;
                end
                `pop: begin
                    SP        <= SP + 1;
                    GPR[rdst] <= data_mem[SP + 1];
                end
                `halt: stop <= 1;
            endcase

           
            if (stall) begin
            
                IR_exec  <= IR_exec;
                IR_fetch <= IR_fetch;
                PC       <= PC;
            end else if (branch_taken) begin
                
                PC       <=  target_pc;
                IR_exec  <= 32'b0;
                IR_fetch <= inst_mem[ target_pc];
            end else begin
                IR_fetch <= inst_mem[PC+1];
                IR_exec  <= IR_fetch;
                PC       <= PC + 1;
            end
        end

        // BUSY_WAIT 
        BUSY_WAIT: begin
            case(CTRL_REG[3:0])
                `PERI_UART_TX: begin
                    // Bug7 fix: only need to load UART_REG once; re-writing
                    // every cycle is harmless but wasteful - guard with !uart_busy
                    // so it only loads right when ready to send
                    if (!uart_busy) begin
                        UART_REG   <= ctrl_data[7:0];
                        uart_start <= 1'b1;
                    end
                end

                `PERI_UART_RX: begin
                    if (irq) begin
                        UART_REG              <= uart_rx_data;
                        GPR[rdst_latch][7:0]  <= uart_rx_data;
                        cu_ack                <= 1'b1;
                    end
                end

                `PERI_GPIO_OUT: gpio_out <= ctrl_data[7:0];
                `PERI_GPIO_IN:  GPR[rdst_latch] <= {8'b0, gpio_in};

                `PERI_TIMER: begin
                
                    if (!timerenable) begin
                        timerdir    <= ctrl_data[15];
                        timerload   <= GPR[ctrl_data[14:10]];
                        timertarget <= GPR[ctrl_data[9:5]];
                        timerenable <= 1'b1;
                    end else if (timerdone) begin
                        timerenable <= 1'b0;
                    end
                end

                `PERI_PWM: begin
                    pwmperiod <= ctrl_data[15:8];
                    pwmduty   <= ctrl_data[7:0];
                    pwmenable <= 1'b1;
                end

                
                `PERI_SPI: begin
                    if (!spi_enable) begin
                        spi_tx_data <= ctrl_data[7:0];
                        spi_enable  <= 1'b1;
                    end else if (spi_done) begin
                        GPR[rdst_latch][15:8] <= spi_rx_data;
                        spi_enable             <= 1'b0;
                    end
                end

      `PERI_SPI_SLAVE_TX: begin
        spi_slave_tx_data <= ctrl_data[7:0];
    end

    `PERI_SPI_SLAVE_RX: begin
        if (spi_slave_rx_valid) begin
            GPR[rdst_latch][7:0] <= spi_slave_rx_byte;
        end
        // not valid -> GPR untouched, single cycle, no stall, exactly as asked
    end

    `PERI_SEG7: begin
        seg7_value <= ctrl_data;
    end

                default: ;
            endcase
        end

       
        HALT: begin
            stop <= 1'b1;
        end

        endcase
    end
end

endmodule

//  UART TX 
module uart_tx(
    input            clk, rst, tx_start,
    input      [7:0] data_in,
    output reg        tx, tx_done, busy
);
parameter BAUD_DIV = 4;
parameter IDLE = 0, SEND = 1;
reg [1:0]  state, next_state;
reg [9:0]  sample;
reg [3:0]  i;
reg [15:0] baud_cnt;

always @(posedge clk or posedge rst)
    state <= rst ? IDLE : next_state;

always @(*) begin
    case(state)
        IDLE: next_state = tx_start ? SEND : IDLE;
        SEND: next_state = (i == 10) ? IDLE : SEND;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        tx <= 1; busy <= 0; tx_done <= 0;
        i <= 0; baud_cnt <= 0; sample <= 10'h3FF;
    end else begin
        tx_done <= (i == 10);
        case(state)
            IDLE: begin
                tx <= 1; busy <= 0; i <= 0; baud_cnt <= 0;
                if (tx_start) sample <= {1'b1, data_in, 1'b0};
            end
            SEND: begin
                busy <= 1;
                if (baud_cnt == BAUD_DIV-1) begin
                    baud_cnt <= 0;
                    tx       <= sample[i];
                    i        <= i + 1;
                end else
                    baud_cnt <= baud_cnt + 1;
            end
        endcase
    end
end
endmodule

//  UART RX
module uart_rx(
    input             clk, rst, rx, cpu_ack,
    output reg [7:0]  data_out,
    output reg         data_valid
);
parameter BAUD_DIV = 4;
parameter IDLE=0, START_BIT=1, RECEIVE=2, STOP_BIT=3;
reg [1:0]  state, next_state;
reg [3:0]  i;
reg [15:0] baud_cnt;

always @(posedge clk or posedge rst)
    state <= rst ? IDLE : next_state;

always @(*) begin
    case(state)
        IDLE     : next_state = (rx==0) ? START_BIT : IDLE;
        START_BIT: next_state = (baud_cnt==(BAUD_DIV/2)-1) ? (rx==0 ? RECEIVE : IDLE) : START_BIT;
        RECEIVE  : next_state = (baud_cnt==BAUD_DIV-1 && i==8) ? STOP_BIT : RECEIVE;
        STOP_BIT : next_state = (baud_cnt==BAUD_DIV-1) ? IDLE : STOP_BIT;
        default  : next_state = IDLE;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_valid <= 0; data_out <= 0; i <= 0; baud_cnt <= 0;
    end else begin
        case(state)
            IDLE: begin
                if (cpu_ack) data_valid <= 0;
                i <= 0; baud_cnt <= 0;
            end
            START_BIT:
                baud_cnt <= (baud_cnt==(BAUD_DIV/2)-1) ? 0 : baud_cnt+1;
            RECEIVE: begin
                if (baud_cnt==BAUD_DIV-1) begin
                    baud_cnt <= 0;
                    if (i < 8) begin data_out[i] <= rx; i <= i+1; end
                end else baud_cnt <= baud_cnt+1;
            end
            STOP_BIT: begin
                if (baud_cnt==BAUD_DIV-1) begin
                    baud_cnt <= 0;
                    if (rx) data_valid <= 1;
                end else baud_cnt <= baud_cnt+1;
            end
        endcase
    end
end
endmodule

module timer(
    input             clk, rst, enable,
    input             dir,
    input      [15:0] target_value,
    input      [15:0] load_value,
    output reg [15:0] timer_value,
    output reg         done
);
reg enable_prev;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        timer_value <= 0; done <= 0; enable_prev <= 0;
    end else begin
        enable_prev <= enable;
        if (enable) begin
            if (!enable_prev)
                timer_value <= load_value;
            else begin
                if (dir == 0) begin
                    if (timer_value < target_value) begin
                        timer_value <= timer_value + 1; done <= 0;
                    end else done <= 1;
                end else begin
                    if (timer_value > target_value) begin
                        timer_value <= timer_value - 1; done <= 0;
                    end else done <= 1;
                end
            end
        end else done <= 0;
    end
end
endmodule

module pwm(
    input clk, rst, enable,
    input [7:0] period,
    input [7:0] duty,
    output reg pwm_out
);
reg [7:0] counter;
reg       enable_prev;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 0; enable_prev <= 0; pwm_out <= 0;
    end else begin
        enable_prev <= enable;
        if (enable) begin
            if (!enable_prev) counter <= 0;
            else if (counter < period - 1) counter <= counter + 1;
            else counter <= 0;
            pwm_out <= (counter < duty) ? 1'b1 : 1'b0;
        end
    end
end
endmodule

module spi_master(
    input             clk, rst, enable,
    input      [7:0]  spi_tx_data,
    input             MISO,
    output reg        MOSI,
    output reg        SCLK,
    output reg        CS,
    output reg [7:0]  spi_rx_data,
    output reg        spi_busy,
    output reg        spi_done
);
reg [7:0] shift_reg;
reg [3:0] bit_cnt;
reg       enable_prev;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        MOSI <= 0; SCLK <= 0; CS <= 1'b1; bit_cnt <= 0;
        enable_prev <= 1'b0; shift_reg <= 8'h00;
        spi_rx_data <= 8'h00; spi_busy <= 0; spi_done <= 0;
    end else begin
        enable_prev <= enable;
        if (enable) begin
            if (!enable_prev) begin
                bit_cnt   <= 0;
                shift_reg <= spi_tx_data;
                spi_busy  <= 1'b1;
                spi_done  <= 1'b0;
                CS        <= 1'b0;
                MOSI      <= spi_tx_data[7];
            end else if (bit_cnt < 8) begin
                MOSI      <= shift_reg[6];
                shift_reg <= {shift_reg[6:0], MISO};
                bit_cnt   <= bit_cnt + 1;
            end else begin
                spi_rx_data <= shift_reg;
                spi_busy    <= 1'b0;
                spi_done    <= 1'b1;
                CS          <= 1'b1;
            end
        end else begin
            spi_busy <= 1'b0;
            spi_done <= 1'b0;
            CS       <= 1'b1;
        end
    end
end
endmodule

module spi_slave(
    input            clk,      // system clock (NOT the SPI clock)
    input            rst,
    input            SCLK,     // from external master
    input            CS,       // from external master, active low
    input            MOSI,     // from external master
    output reg       MISO,     // to external master
    input  [7:0]     tx_data,  // byte to send back, loaded continuously by CPU
    output reg [7:0] rx_data,  // last byte received
    output reg       done      // 1-cycle pulse when a full byte has been received
);

    reg [2:0] sclk_sync, cs_sync, mosi_sync;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sclk_sync <= 3'b000;
            cs_sync   <= 3'b111;
            mosi_sync <= 3'b000;
        end else begin
            sclk_sync <= {sclk_sync[1:0], SCLK};
            cs_sync   <= {cs_sync[1:0],   CS};
            mosi_sync <= {mosi_sync[1:0], MOSI};
        end
    end

    wire sclk_rise  =  sclk_sync[1] & ~sclk_sync[2];
    wire sclk_fall  = ~sclk_sync[1] &  sclk_sync[2];
    wire cs_active  = ~cs_sync[1];      // active low
    wire mosi_bit   =  mosi_sync[1];

    reg [2:0] bit_cnt;
    reg [7:0] shift_in;
    reg [7:0] shift_out;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt   <= 3'd0;
            shift_in  <= 8'd0;
            shift_out <= 8'd0;
            rx_data   <= 8'd0;
            done      <= 1'b0;
            MISO      <= 1'b0;
        end else begin
            done <= 1'b0;

            if (!cs_active) begin
                // Deselected: reload the byte we'll send next time we're selected,
                // and reset bit count so we start cleanly on the next CS assert.
                bit_cnt   <= 3'd0;
                shift_out <= tx_data;
                MISO      <= tx_data[7];
            end else begin
                if (sclk_rise) begin
                    shift_in <= {shift_in[6:0], mosi_bit};
                    bit_cnt  <= bit_cnt + 1'b1;
                    if (bit_cnt == 3'd7) begin
                        rx_data <= {shift_in[6:0], mosi_bit};
                        done    <= 1'b1;
                    end
                end
                if (sclk_fall) begin
                    shift_out <= {shift_out[6:0], 1'b0};
                    MISO      <= shift_out[6];
                end
            end
        end
    end
endmodule
`timescale 1ns / 1ps

module seg7_driver(
    input             clk, rst,
    input      [15:0] value,
    output reg [6:0]  seg,   // {g,f,e,d,c,b,a} active-low
    output reg [3:0]  an     // active-low digit enable
);

    reg [17:0] refresh_cnt;
    always @(posedge clk or posedge rst)
        if (rst) refresh_cnt <= 18'd0;
        else     refresh_cnt <= refresh_cnt + 1'b1;

    wire [1:0] digit_sel = refresh_cnt[17:16]; // ~750 Hz refresh @100MHz clk

    reg [3:0] nibble;
    always @(*) begin
        case (digit_sel)
            2'b00: nibble = value[3:0];
            2'b01: nibble = value[7:4];
            2'b10: nibble = value[11:8];
            2'b11: nibble = value[15:12];
        endcase
    end

    always @(posedge clk or posedge rst) begin
        if (rst) an <= 4'b1111;
        else case (digit_sel)
            2'b00: an <= 4'b1110;
            2'b01: an <= 4'b1101;
            2'b10: an <= 4'b1011;
            2'b11: an <= 4'b0111;
        endcase
    end

    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end
endmodule