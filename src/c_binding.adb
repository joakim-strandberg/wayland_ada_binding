package body C_Binding is

   function "-" (Text : C_String) return String is
   begin
      return String (Text (Text'First .. Text'Last - 1));
   end "-";

   function "+" (Text : String) return C_String is
   begin
      return C_String (Text & Nul);
   end "+";

--     function "+" (Text : String) return chars_ptr is
--        Chars : aliased Interfaces.C.char_array :=
--          Interfaces.C.To_C (Text);
--     begin
--        return Interfaces.C.Strings.To_Chars_Ptr (Chars'Unchecked_Access);
--        --  There doesn't seem to exist a way to convert a String into
--        --
--     end "+";
--
   function "-" (Chars : chars_ptr) return String is
      A : constant Interfaces.C.char_array
        := Interfaces.C.Strings.Value (Chars);
   begin
      return Interfaces.C.To_Ada (A);
   end "-";

end C_Binding;
