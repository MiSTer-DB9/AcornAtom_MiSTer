//============================================================================
//  Acorn Atom port to MiSTer
//  2020 Dave Wood
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [48:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	//if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
	output [12:0] VIDEO_ARX,
	output [12:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output [1:0]  VGA_SL,
	output        VGA_SCALER, // Force VGA scaler
	output        VGA_DISABLE, // analog out is off

	input  [11:0] HDMI_WIDTH,
	input  [11:0] HDMI_HEIGHT,
	output        HDMI_FREEZE,
	output        HDMI_BLACKOUT,
	output        HDMI_BOB_DEINT,

`ifdef MISTER_FB
	// Use framebuffer in DDRAM
	// FB_FORMAT:
	//    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
	//    [3]   : 0=16bits 565 1=16bits 1555
	//    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
	//
	// FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
	output        FB_EN,
	output  [4:0] FB_FORMAT,
	output [11:0] FB_WIDTH,
	output [11:0] FB_HEIGHT,
	output [31:0] FB_BASE,
	output [13:0] FB_STRIDE,
	input         FB_VBL,
	input         FB_LL,
	output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
	// Palette control for 8bit modes.
	// Ignored for other video modes.
	output        FB_PAL_CLK,
	output  [7:0] FB_PAL_ADDR,
	output [23:0] FB_PAL_DOUT,
	input  [23:0] FB_PAL_DIN,
	output        FB_PAL_WR,
`endif
`endif

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	input         CLK_AUDIO, // 24.576 MHz
	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
	//Secondary SDRAM
	//Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
	input         SDRAM2_EN,
	output        SDRAM2_CLK,
	output [12:0] SDRAM2_A,
	output  [1:0] SDRAM2_BA,
	inout  [15:0] SDRAM2_DQ,
	output        SDRAM2_nCS,
	output        SDRAM2_nCAS,
	output        SDRAM2_nRAS,
	output        SDRAM2_nWE,
`endif

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_OSD + USER_PP, USER_IN/OUT widened to 8 bits
	output        USER_OSD,
	output  [7:0] USER_PP,
	input   [7:0] USER_IN,
	output  [7:0] USER_OUT,
	// [MiSTer-DB9 END]

	input         OSD_STATUS
);


assign ADC_BUS  = 'Z;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USER_PP driver
assign USER_PP = USER_PP_DRIVE;
// [MiSTer-DB9 END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper
wire         CLK_JOY = CLK_50M;                 // Assign clock between 40-50Mhz
wire   [1:0] joy_type_raw    = status[127:126]; // 0=Off, 1=Saturn, 2=DB9MD, 3=DB15
wire         joy_2p          = status[125];     // 2P core: UserIO Players selector
wire         snac_active     = 1'b0;
wire         mt32_primary_active = 1'b0;
wire   [1:0] joy_type        = snac_active ? 2'd0 : joy_type_raw;
wire         joy_db9md_en    = (joy_type == 2'd2);
wire         joy_db15_en     = (joy_type == 2'd3);
wire         joy_any_en      = |joy_type;
// [MiSTer-DB9 END]

// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
wire         saturn_unlocked;                   // driven by hps_io UIO_DB9_KEY (0xFE)
// [MiSTer-DB9-Pro END]

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joydb wrapper wires + instance
wire   [7:0] USER_OUT_DRIVE;
wire   [7:0] USER_PP_DRIVE;
wire  [15:0] joydb_1, joydb_2;
wire         joydb_1ena, joydb_2ena;
wire         pad_1_6btn, pad_2_6btn;
wire  [15:0] joy_raw_payload;

// [MiSTer-DB9 BEGIN] - DB9 programmable-remap matrix wires
// joydb_*_mapped = MiSTer-standard joystick words (consumed in Layer B);
// db9_remap_* = 0xFD selector stream driven by the hps_io instance.
wire  [15:0] joydb_1_mapped, joydb_2_mapped;
wire         db9_remap_cmd;
wire   [5:0] db9_remap_byte_cnt;
wire  [15:0] db9_remap_din;
// [MiSTer-DB9 END]
joydb joydb (
  .clk             ( CLK_JOY         ),
  .clk_sys         ( clk_sys            ),
  .USER_IN         ( USER_IN         ),
  .OSD_STATUS          ( OSD_STATUS          ),
  .snac_active         ( snac_active         ),
  .mt32_primary_active ( mt32_primary_active ),
  .joy_type        ( joy_type        ),
  .joy_2p          ( joy_2p          ),
  .saturn_unlocked ( saturn_unlocked ),
  .USER_OUT_DRIVE  ( USER_OUT_DRIVE  ),
  .USER_PP_DRIVE   ( USER_PP_DRIVE   ),
  .USER_OSD        ( USER_OSD        ),
  .joydb_1         ( joydb_1         ),
  .joydb_2         ( joydb_2         ),
  .joydb_1ena      ( joydb_1ena      ),
  .joydb_2ena      ( joydb_2ena      ),
  .remap_cmd       ( db9_remap_cmd      ),
  .remap_byte_cnt  ( db9_remap_byte_cnt ),
  .remap_din       ( db9_remap_din      ),
  .joydb_1_mapped  ( joydb_1_mapped     ),
  .joydb_2_mapped  ( joydb_2_mapped     ),
  .pad_1_6btn      ( pad_1_6btn      ),
  .pad_2_6btn      ( pad_2_6btn      ),
  .joy_raw         ( joy_raw_payload )
);

assign USER_OUT = USER_OUT_DRIVE;
// [MiSTer-DB9 END]

assign UART_RTS = UART_CTS;
assign UART_DTR = UART_DSR;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign UART_TXD = 0;
//assign LED_USER  = 0;
assign LED_DISK  = {1'b1,~vsd_sel & sd_act};
assign LED_POWER = 0;
assign BUTTONS   = 0;

assign VGA_DISABLE = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;
assign HDMI_BLACKOUT = 0;
assign HDMI_BOB_DEINT = 0;

wire [1:0] ar = status[12:11];

assign VIDEO_ARX = (!ar) ? 12'd4 : (ar - 1'd1);
assign VIDEO_ARY = (!ar) ? 12'd3 : 12'd0;


`include "build_id.v" 
parameter CONF_STR = {
	"AcornAtom;;",
	"-;",
	"S,VHD;",
	"-;",
	"OBC,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
	"O13,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%;", 
	"-;",
	"O45,Audio,Atom,SID,TAPE,off;",
	"O67,Keyboard,UK,US,orig,game;",
	"O8,character set,original,xtra;",
	"O9,Background,Black,Dark;",
	"OA,Mode,Atom,BBC;",
	"-;",
	"R0,Reset;",
	// [MiSTer-DB9-Pro BEGIN] - Saturn-first joy_type (canonical bit notation)
	"-;",
	"O[127:126],UserIO Joystick,Off,Saturn,DB9MD,DB15;",
	"O[125],UserIO Players,1 Player,2 Players;",
	// [MiSTer-DB9-Pro END]
	"JA,Fire;",
	"V,v",`BUILD_DATE
};

/////////////////  CLOCKS  ////////////////////////
wire clk_main = clk_sys;
wire clk_sys = clk_32;
//wire clk_100;
wire clk_16;
wire clk_32;
//wire clk_25;
wire clk_42;
wire pll_locked;

pll pll
(
	.refclk(CLK_50M),
	.rst(0),
	.outclk_0(clk_42),
	.outclk_1(clk_32),
	.outclk_2(clk_16)

);

reg clk_14M318_ena ;
reg [1:0] count;


always @(posedge clk_42)
begin
	if (reset)
		count<=0;
	else
	begin
		clk_14M318_ena <= 0;
		if (count == 'd2)
		begin
		  clk_14M318_ena <= 1;
        count <= 0;
		end
		else
		begin
			count<=count+1;
		end
	end
end



/////////////////  HPS  ///////////////////////////

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: status widened to 128 bits
wire [127:0] status;
// [MiSTer-DB9 END]
wire  [1:0] buttons;

// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joysticks renamed + joydb mux
wire [15:0] joy1_USB, joy2_USB;
wire [15:0] joy1 = joydb_1ena ? (OSD_STATUS ? 16'b0 : joydb_1_mapped[15:0]) : joy1_USB;
wire [15:0] joy2 = joydb_2ena ? (OSD_STATUS ? 16'b0 : joydb_2_mapped[15:0]) : (joydb_1ena ? joy1_USB : joy2_USB);
// [MiSTer-DB9 END]

wire [10:0] ps2_key;
wire [24:0] ps2_mouse;

wire        ioctl_download;
wire  [7:0] ioctl_index;
wire        ioctl_wr;
wire [24:0] ioctl_addr;
wire [7:0]  ioctl_dout;
wire        forced_scandoubler;
wire [21:0] gamma_bus;
wire        direct_video;

wire [31:0] sd_lba[1];
wire        sd_rd;
wire        sd_wr;
wire        sd_ack;
wire  [8:0] sd_buff_addr;
wire [7:0]  sd_buff_dout;
wire [7:0]  sd_buff_din[1];
wire        sd_buff_wr;
wire        img_mounted;
wire        img_readonly;
wire [63:0] img_size;


wire ps2_clk,ps2_data;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
	.clk_sys(clk_sys),
	.HPS_BUS(HPS_BUS),


	.buttons(buttons),
	.status(status),
	.forced_scandoubler(forced_scandoubler),
	.gamma_bus(gamma_bus),
	.direct_video(direct_video),
	

	.ps2_key(ps2_key),
	.ps2_mouse(ps2_mouse),
	.ps2_kbd_clk_out(ps2_clk),
	.ps2_kbd_data_out(ps2_data),

	.ioctl_download(ioctl_download),
	.ioctl_index(ioctl_index),
	.ioctl_wr(ioctl_wr),
	.ioctl_addr(ioctl_addr),
	.ioctl_dout(ioctl_dout),
	
	//.uart_mode(16'b000_11111_000_11111),

	.sd_lba(sd_lba),
	.sd_rd(sd_rd),
	.sd_wr(sd_wr),
	.sd_ack(sd_ack),

	.sd_buff_addr(sd_buff_addr),
	.sd_buff_dout(sd_buff_dout),
	.sd_buff_din(sd_buff_din),
	.sd_buff_wr(sd_buff_wr),
	.img_mounted(img_mounted),
	.img_readonly(img_readonly),
	.img_size(img_size),

	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: USB-side joysticks renamed
	.joystick_0(joy1_USB),
	.joystick_1(joy2_USB),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9 BEGIN] - DB9/SNAC8 support: joy_raw for OSD autodetect
	.joy_raw(OSD_STATUS ? joy_raw_payload : 16'b0),
	// programmable remap matrix selector load (UIO_DB9_MAP 0xFD)
	.db9_remap_cmd(db9_remap_cmd),
	.db9_remap_byte_cnt(db9_remap_byte_cnt),
	.db9_remap_din(db9_remap_din),
	// [MiSTer-DB9 END]
	// [MiSTer-DB9-Pro BEGIN] - Saturn key gate
	.saturn_unlocked(saturn_unlocked)
	// [MiSTer-DB9-Pro END]
);

/////////////////  RESET  /////////////////////////

wire reset = RESET | status[0] | buttons[1];

////////////////  MEMORY  /////////////////////////

/* MAP

64k Atom memory map
00000 ram 
01000 ram
02000 ram
03000 ram
04000 ram
05000 ram
06000 ram
07000 ram

08000 ram video
09000 ram video
0A000 ram/rom used for paging 8 additional roms
0B000 bran_b010.rom + I/O
0C000 abasic.rom
0D000 afloat_patched_b010.rom
0E000 atommc3_avr.rom
0F000 akernel_patched.rom

 additional roms - slot 7 is ram and can be filled with utility rom download
10000 axr1.rom
11000 pcharme_v1.73.rom
12000 atomic_windows_v1.1.rom
13000 gags_v2.3.rom
14000 pp_toolkit.rom
15000 we_rom.rom
16000 fpgautil.rom
17000 ram

18000-1f000 space - filler

64k Atom memory map with BBC basic and mmc roms
20000 ram
21000 ram
22000 ram
23000 ram
24000 ram
25000 ram
26000 atom_bbc_ext1.rom
27000 atom_bbc_ext2_avr.rom

28000 ram video
29000 ram video
2A000 bbc_a000.rom
2B000 I/O
2C000 bbc_c000.rom
2D000 bbc_d000.rom
2E000 bbc_e000.rom
2F000 bbc_f000.rom
*/

wire        mem_we,rom_cs;
wire [17:0] mem_addr;
wire  [7:0] mem_din,mem_dout;


spram #(8, 18, 196608, "roms/ATOM192k.mif") rom
(
	.clock(clk_main),
	.address(mem_addr),
	.data(mem_din),
	.wren(mem_we),
	.q(mem_dout)
);


///////////////////////////////////////////////////

wire charset = status[8];

wire tape_out;
wire pixel_clock;
AtomFpga_Core AcornAtom
(
			// clocks
			
	.clk_vid(clk_42),
	.clk_vid_en(clk_14M318_ena),
	.clk_main(clk_main),
	.clk_dac(clk_sys),  // -2.202 setup slack
	//.clk_avr(clk_16), // -4.98 setup slack -- this is to fix SD Card problem
	.clk_avr(clk_main), // this helps timing
	
	.pixel_clock(pixel_clock),
	
        // Keyboard
	.ps2_key(ps2_key),
	.layout(status[7:6]),
	.BLACK_BACKGND(~status[9]),
	.computer(status[10]),

        // Mouse
//   .ps2_mouse_clk(mse_clk),	//  : inout std_logic;
//   .ps2_mouse_data(mse_clk),	// : inout std_logic;
	
		//resets
//	.powerup_reset_n(~RESET),
	.ext_reset_n(~reset),
//	.int_reset_n(),

    // VGA
	.red(r),
        .green(g),
	.blue(b),
	.hsync(hs),
	.vsync(vs),
	.hblank(hblank),
	.vblank(vblank),
	
		// External 6502 bus interface
//	.phi2(),
//	.sync(),
//	.rnw(),
//	.blk_b(),
//	.addr(),
//	.rdy(1'b1),
//	.so(1'b1),
//	.irq_n(1'b1),
//	.nmi_n(1'b1),
	
		// External Bus/Ram/Rom interface
//	.ExternBus(),
//	.ExternCE(),
	.ExternROM(rom_cs),
	.ExternWE(mem_we),
	.ExternDout(mem_dout),
	.ExternDin(mem_din),
	.ExternA(mem_addr),


        // Audio
	.atom_audio(a_audio),	//          : out   std_logic;
	.sid_audio(),
	.sid_audio_d(sid_audio),
	
        // SD Card
	.SDCLK(sdclk),	//        : out   std_logic;
	.SDSS(sdss),	//         : out   std_logic;
	.SDMOSI(sdmosi),	//       : out   std_logic;
	.SDMISO(sdmiso),	//       : in    std_logic;

        // Serial
//   .uart_TxD(),	//      : out   std_logic;
//   .uart_RxD(1'B0),	//      : in    std_logic;
	
        // Cassette
	.cas_in(tape_adc),	//         : in    std_logic;
	.cas_out(tape_out),	//        : out   std_logic;
	
		// Misc
	.LED1(LED_USER),
	.LED2(),
	.charset(charset),
	.Joystick1(~joy1),
	.Joystick2(~joy2),


        // USB Uart on FPGA Module
   .avr_TxD(),     //       : out   std_logic;
   .avr_RxD(1'b0)  //       : in    std_logic

);

wire [17:0] sid_audio;
wire a_audio;

assign AUDIO_L = status[5:4] == 2'b00 ? {{16{a_audio}}} : status[5:4] == 2'b01 ? sid_audio[17:2] : status[5:4] == 2'b10 ? {{16{tape_out}}} : 16'b0 ;
assign AUDIO_R = status[5:4] == 2'b00 ? {{16{a_audio}}} : status[5:4] == 2'b01 ? sid_audio[17:2] : status[5:4] == 2'b10 ? {{16{tape_out}}} : 16'b0 ;
assign AUDIO_MIX = 0;
assign AUDIO_S = 1'b0;

wire hs, vs, hblank, vblank,  clk_sel;
wire [1:0] r,g,b;

assign CLK_VIDEO = clk_42;// clk_25;
wire freeze_sync;



video_mixer #(.GAMMA(1)) video_mixer
(
   .*,

   .CLK_VIDEO(CLK_VIDEO),
   .ce_pix(pixel_clock),

	.hq2x(scale==1),


	.R({r[1],r[1],r[1],r[0],r[0],r[0],r}),
	.G({g[1],g[1],g[1],g[0],g[0],g[0],g}),
	.B({b[1],b[1],b[1],b[0],b[0],b[0],b}),

   .HSync(~hs),
   .VSync(~vs),
   .HBlank(hblank),
   .VBlank(vblank)
);



assign VGA_F1 = 0;
reg [2:0] scale;
always @(posedge clk_42) scale = status[3:1];
wire [2:0] sl = scale ? scale - 1'd1 : 3'd0;
wire       scandoubler = (scale || forced_scandoubler);
assign VGA_SL = sl[1:0];

//////////////////   SD   ///////////////////

wire sdclk;
wire sdmosi;
wire sdmiso = vsd_sel ? vsdmiso : SD_MISO;
wire sdss;

reg vsd_sel = 0;
always @(posedge clk_sys) if(img_mounted) vsd_sel <= |img_size;

wire vsdmiso;
sd_card #(0) sd_card
(
	.*,

	.sd_lba(sd_lba[0]),
	.sd_buff_din(sd_buff_din[0]),

	.clk_spi(clk_sys),
	.sdhc(1),
	.sck(sdclk),
	.ss(sdss | ~vsd_sel),
	.mosi(sdmosi),
	.miso(vsdmiso)
);

assign SD_CS   = sdss   |  vsd_sel;
assign SD_SCK  = sdclk  & ~vsd_sel;
assign SD_MOSI = sdmosi & ~vsd_sel;

reg sd_act;

always @(posedge clk_sys) begin
	reg old_mosi, old_miso;
	integer timeout = 0;

	old_mosi <= sdmosi;
	old_miso <= sdmiso;

	sd_act <= 0;
	if(timeout < 2000000) begin
		timeout <= timeout + 1;
		sd_act <= 1;
	end

	if((old_mosi ^ sdmosi) || (old_miso ^ sdmiso)) timeout <= 0;
end

wire tape_adc, tape_adc_act;
ltc2308_tape ltc2308_tape
(
	.clk(CLK_50M),
	.ADC_BUS(ADC_BUS),
	.dout(tape_adc),
	.active(tape_adc_act)
);


endmodule

//////////////////////////////////////////////

module spram #(parameter DATAWIDTH=8, ADDRWIDTH=8, NUMWORDS=1<<ADDRWIDTH, MEM_INIT_FILE="")
(
	input	                 clock,
	input	 [ADDRWIDTH-1:0] address,
	input	 [DATAWIDTH-1:0] data,
	input	                 wren,
	output [DATAWIDTH-1:0] q
);

altsyncram altsyncram_component
(
	.address_a (address),
	.clock0 (clock),
	.data_a (data),
	.wren_a (wren),
	.q_a (q),
	.aclr0 (1'b0),
	.aclr1 (1'b0),
	.address_b (1'b1),
	.addressstall_a (1'b0),
	.addressstall_b (1'b0),
	.byteena_a (1'b1),
	.byteena_b (1'b1),
	.clock1 (1'b1),
	.clocken0 (1'b1),
	.clocken1 (1'b1),
	.clocken2 (1'b1),
	.clocken3 (1'b1),
	.data_b (1'b1),
	.eccstatus (),
	.q_b (),
	.rden_a (1'b1),
	.rden_b (1'b1),
	.wren_b (1'b0)
);

defparam
	altsyncram_component.clock_enable_input_a = "BYPASS",
	altsyncram_component.clock_enable_output_a = "BYPASS",
	altsyncram_component.init_file = MEM_INIT_FILE,
	altsyncram_component.intended_device_family = "Cyclone V",
	altsyncram_component.lpm_type = "altsyncram",
	altsyncram_component.numwords_a = NUMWORDS,
	altsyncram_component.operation_mode = "SINGLE_PORT",
	altsyncram_component.outdata_aclr_a = "NONE",
	altsyncram_component.outdata_reg_a = "UNREGISTERED",
	altsyncram_component.power_up_uninitialized = "FALSE",
	altsyncram_component.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
	altsyncram_component.widthad_a = ADDRWIDTH,
	altsyncram_component.width_a = DATAWIDTH,
	altsyncram_component.width_byteena_a = 1;


endmodule
