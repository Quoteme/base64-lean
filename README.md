# base64-lean

![Screenshot](assets/screenshot.png)

A simple Base64 encoding and decoding library for Lean4 without any
dependencies. Completely written in Lean4. Cross platform.

```lean
-- Example usage
#eval Base64.encode "Hello, World!".toUTF8
#eval Base64.decode "SGVsbG8sIFdvcmxkIQ==" |>.map String.fromUTF8!
```
