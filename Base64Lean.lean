-- Minimal Base64 implementation in Lean4
--
def alphabet : String := "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

def encodeChar (n : Nat) : Char :=
  alphabet.get! ⟨n % 64⟩

def encode (bytes : ByteArray) : String :=
  let rec go (i : Nat) (acc : String) : String :=
    if h : i + 2 < bytes.size then
      let b1 := bytes[i]!
      let b2 := bytes[i+1]!
      let b3 := bytes[i+2]!
      let n := (b1.toNat <<< 16) ||| (b2.toNat <<< 8) ||| b3.toNat
      let c1 := encodeChar (n >>> 18)
      let c2 := encodeChar ((n >>> 12) &&& 0x3f)
      let c3 := encodeChar ((n >>> 6) &&& 0x3f)
      let c4 := encodeChar (n &&& 0x3f)
      go (i + 3) (acc ++ c1.toString ++ c2.toString ++ c3.toString ++ c4.toString)
    else if i + 1 < bytes.size then
      -- Two bytes remaining
      let b1 := bytes[i]!
      let b2 := bytes[i+1]!
      let n := (b1.toNat <<< 16) ||| (b2.toNat <<< 8)
      let c1 := encodeChar (n >>> 18)
      let c2 := encodeChar ((n >>> 12) &&& 0x3f)
      let c3 := encodeChar ((n >>> 6) &&& 0x3f)
      acc ++ c1.toString ++ c2.toString ++ c3.toString ++ "="
    else if i < bytes.size then
      -- One byte remaining
      let b1 := bytes[i]!
      let n := b1.toNat <<< 16
      let c1 := encodeChar (n >>> 18)
      let c2 := encodeChar ((n >>> 12) &&& 0x3f)
      acc ++ c1.toString ++ c2.toString ++ "=="
    else
      acc
  go 0 ""

def decodeChar (c : Char) : Option Nat :=
  if 'A' ≤ c ∧ c ≤ 'Z' then some (c.toNat - 'A'.toNat)
  else if 'a' ≤ c ∧ c ≤ 'z' then some (c.toNat - 'a'.toNat + 26)
  else if '0' ≤ c ∧ c ≤ '9' then some (c.toNat - '0'.toNat + 52)
  else if c = '+' then some 62
  else if c = '/' then some 63
  else none

def decode (s : String) : Option ByteArray :=
  let chars := s.toList.filter (· ≠ '=')
  let rec go (cs : List Char) (acc : ByteArray) : Option ByteArray :=
    match cs with
    | [] => some acc
    | c1 :: c2 :: c3 :: c4 :: rest =>
      match decodeChar c1, decodeChar c2, decodeChar c3, decodeChar c4 with
      | some n1, some n2, some n3, some n4 =>
        let n := (n1 <<< 18) ||| (n2 <<< 12) ||| (n3 <<< 6) ||| n4
        let b1 := UInt8.ofNat ((n >>> 16) &&& 0xff)
        let b2 := UInt8.ofNat ((n >>> 8) &&& 0xff)
        let b3 := UInt8.ofNat (n &&& 0xff)
        go rest (acc.push b1 |>.push b2 |>.push b3)
      | _, _, _, _ => none
    | c1 :: c2 :: c3 :: [] =>
      match decodeChar c1, decodeChar c2, decodeChar c3 with
      | some n1, some n2, some n3 =>
        let n := (n1 <<< 18) ||| (n2 <<< 12) ||| (n3 <<< 6)
        let b1 := UInt8.ofNat ((n >>> 16) &&& 0xff)
        let b2 := UInt8.ofNat ((n >>> 8) &&& 0xff)
        some (acc.push b1 |>.push b2)
      | _, _, _ => none
    | c1 :: c2 :: [] =>
      match decodeChar c1, decodeChar c2 with
      | some n1, some n2 =>
        let n := (n1 <<< 18) ||| (n2 <<< 12)
        let b1 := UInt8.ofNat ((n >>> 16) &&& 0xff)
        some (acc.push b1)
      | _, _ => none
    | _ => none
  go chars ByteArray.empty
