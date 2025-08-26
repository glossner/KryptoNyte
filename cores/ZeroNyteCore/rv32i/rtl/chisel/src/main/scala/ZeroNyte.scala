package ZeroNyteCore

import chisel3._
import chisel3.util._

/** 
 * ZeroNyte: Simple fetch-execute CPU
 * Supports basic RISC-V style instructions: ADD, SUB, ADDI, BEQ
 */
class ZeroNyte extends Module {
  val io = IO(new Bundle {
    val pc_out = Output(UInt(32.W))    // Current Program Counter
    val instr  = Output(UInt(32.W))    // Current instruction
    val regOut = Output(UInt(32.W))    // Output for testing (register x1)
  })

  // ---------------------------
  // Program Counter
  // ---------------------------
  val pc = RegInit(0.U(32.W))
  io.pc_out := pc

  // ---------------------------
  // Instruction Memory (256 x 32-bit)
  // ---------------------------
  val instrMem = Mem(256, UInt(32.W))

  // ---------------------------
  // Register File (32 x 32-bit)
  // ---------------------------
  val regFile = RegInit(VecInit(Seq.fill(32)(0.U(32.W))))

  // ---------------------------
  // Fetch instruction
  // ---------------------------
  val instr = instrMem(pc)
  io.instr := instr

  // ---------------------------
  // Decode instruction fields
  // ---------------------------
  val opcode = instr(6, 0)
  val rd     = instr(11, 7)
  val funct3 = instr(14, 12)
  val rs1    = instr(19, 15)
  val rs2    = instr(24, 20)
  val funct7 = instr(31, 25)
  val immI   = instr(31, 20)
  val immB   = Cat(instr(31), instr(7), instr(30, 25), instr(11, 8), 0.U(1.W))

  // Default next PC (increment by 1)
  var nextPC = pc + 1.U

  // ---------------------------
  // Simple Execute Logic
  // ---------------------------
  switch(opcode) {
    is("b0010011".U) { // ADDI
      regFile(rd) := regFile(rs1) + immI.asSInt.asUInt
    }
    is("b0110011".U) { // ADD / SUB
      when(funct7 === "b0000000".U && funct3 === "b000".U) { // ADD
        regFile(rd) := regFile(rs1) + regFile(rs2)
      } .elsewhen(funct7 === "b0100000".U && funct3 === "b000".U) { // SUB
        regFile(rd) := regFile(rs1) - regFile(rs2)
      }
    }
    is("b1100011".U) { // BEQ
      when(regFile(rs1) === regFile(rs2)) {
        nextPC = pc + immB.asSInt.asUInt
      }
    }
  }

  // Update PC
  pc := nextPC

  // Output register x1 for testing
  io.regOut := regFile(1)
}

// ---------------------------
// Verilog Generation
// ---------------------------
object ZeroNyteMain extends App {
  (new chisel3.stage.ChiselStage).emitVerilog(
    new ZeroNyte,
    Array("--target-dir", "generated")
  )
}


