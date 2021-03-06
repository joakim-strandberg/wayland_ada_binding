with Ada.Strings.Unbounded;
with Aida.UTF8;

package body Xml_Parser_Utils is

   use all type Ada.Strings.Unbounded.Unbounded_String;
   use all type Aida.UTF8.Code_Point;
   use all type Wayland_XML.Arg_Tag;
   use all type Wayland_XML.Request_Tag;
   use all type Wayland_XML.Interface_Tag;
   use all type Wayland_XML.Protocol_Tag;
   use all type Wayland_XML.Arg_Type_Attribute;
   use all type Wayland_XML.Request_Child_Kind_Id;
   use all type Wayland_XML.Interface_Child_Kind_Id;
   use all type Wayland_XML.Protocol_Child_Kind_Id;

   use type Ada.Containers.Count_Type;

   -- If input is "wl_hello" then output is "hello".
   -- This procedure strips away the first
   -- three characters if they are "wl_".
   procedure Remove_Initial_Wl
     (New_Name : in out Ada.Strings.Unbounded.Unbounded_String) is
   begin
      if Length (New_Name) = 3 and then New_Name = "Wl_" then
         Set_Unbounded_String (New_Name, "");
      end if;
   end Remove_Initial_Wl;

   function Adaify_Variable_Name (Old_Name : String) return String is
      Result : constant String := Adaify_Name (Old_Name);
   begin
      if Result = "Interface" then
         return Result & "_V";
      else
         return Result;
      end if;
   end Adaify_Variable_Name;

   function Adaify_Name (Old_Name : String) return String is
      New_Name : Ada.Strings.Unbounded.Unbounded_String;

      P : Integer := Old_Name'First;

      CP : Aida.UTF8.Code_Point := 0;

      Is_Previous_Lowercase    : Boolean := False;
      Is_Previous_A_Number     : Boolean := False;
      Is_Previous_An_Undercase : Boolean := False;
   begin
      Aida.UTF8.Get (Source => Old_Name, Pointer => P, Value => CP);

      if Is_Uppercase (CP) then
         Append (New_Name, Image (CP));
      else
         Append (New_Name, Image (To_Uppercase (CP)));
      end if;

      while P <= Old_Name'Last loop
         Aida.UTF8.Get (Source => Old_Name, Pointer => P, Value => CP);

         if Image (CP) = "_" then
            Append (New_Name, "_");
            Remove_Initial_Wl (New_Name);
            Is_Previous_An_Undercase := True;
         else
            if Is_Digit (CP) then
               if Is_Previous_A_Number then
                  Append (New_Name, Image (CP));
               elsif Is_Previous_An_Undercase then
                  Append (New_Name, Image (CP));
               else
                  Append (New_Name, "_");
                  Remove_Initial_Wl (New_Name);
                  Append (New_Name, Image (CP));
               end if;

               Is_Previous_A_Number := True;
            else
               if Is_Uppercase (CP) then
                  if Is_Previous_An_Undercase then
                     Append (New_Name, Image (CP));
                  elsif Is_Previous_Lowercase then
                     Append (New_Name, "_");
                     Remove_Initial_Wl (New_Name);
                     Append (New_Name, Image (CP));
                     Is_Previous_Lowercase := False;
                  else
                     Append (New_Name, Image (To_Lowercase (CP)));
                  end if;
               else
                  if Is_Previous_An_Undercase then
                     Append (New_Name, Image (To_Uppercase (CP)));
                  else
                     Append (New_Name, Image (CP));
                  end if;
                  Is_Previous_Lowercase := True;
               end if;

               Is_Previous_A_Number := False;
            end if;

            Is_Previous_An_Undercase := False;
         end if;

      end loop;

      if To_String (New_Name) = "Class_" then
         Set_Unbounded_String (New_Name, "Class_V");
         --       To handle the following case:
         --       <request name="set_class">
         --         ...
         --         <arg name="class_" type="string" summary="surface class"/>
         --       </request>
         --       Identifiers in Ada cannot end with underscore "_".
      end if;

      if To_String (New_Name) = "Delay" then
         Set_Unbounded_String (New_Name, "Delay_V");
         --       To handle:
         --       <arg name="delay" type="int" summary="delay in ..."/>
         --       "delay" is a reserved word in Ada.
      end if;

      return To_String (New_Name);
   end Adaify_Name;

   function Make_Upper_Case (Source : String) return String is
      Target : Ada.Strings.Unbounded.Unbounded_String;

      P : Integer := Source'First;

      CP : Aida.UTF8.Code_Point := 0;
   begin
      Set_Unbounded_String (Target, "");
      while P <= Source'Last loop
         Aida.UTF8.Get (Source => Source, Pointer => P, Value => CP);

         if Image (CP) = "_" then
            Append (Target, "_");
         elsif Is_Digit (CP) then
            Append (Target, Image (CP));
         elsif Is_Lowercase (CP) then
            Append (Target, Image (To_Uppercase (CP)));
         else
            Append (Target, Image (CP));
         end if;

      end loop;

      return To_String (Target);
   end Make_Upper_Case;

   function Arg_Type_As_String (Arg_Tag : Wayland_XML.Arg_Tag) return String is
      N : Ada.Strings.Unbounded.Unbounded_String;
   begin
      case Type_Attribute (Arg_Tag) is
         when Type_Integer =>
            Set_Unbounded_String (N, "Integer");
         when Type_Unsigned_Integer =>
            Set_Unbounded_String (N, "Unsigned_32");
         when Type_String =>
            Set_Unbounded_String (N, "chars_ptr");
         when Type_FD =>
            Set_Unbounded_String (N, "Integer");
         when Type_New_Id =>
            Set_Unbounded_String (N, "Unsigned_32");
         when Type_Object =>
            if Exists_Interface_Attribute (Arg_Tag) then
               Set_Unbounded_String
                 (N, Adaify_Name (Interface_Attribute (Arg_Tag)) & "_Ptr");
            else
               Set_Unbounded_String (N, "Void_Ptr");
            end if;
         when Type_Fixed =>
            Set_Unbounded_String (N, "Fixed");
         when Type_Array =>
            Set_Unbounded_String (N, "Wayland_Array_T");
      end case;
      return To_String (N);
   end Arg_Type_As_String;

   function Number_Of_Args
     (Request_Tag : aliased Wayland_XML.Request_Tag) return Natural is
      N : Natural := 0;
   begin
      for Child of Children (Request_Tag) loop
         if Child.Kind_Id = Child_Arg then
            N := N + 1;
         end if;
      end loop;
      return N;
   end Number_Of_Args;

   function Is_New_Id_Argument_Present
     (Request_Tag : aliased Wayland_XML.Request_Tag) return Boolean is
   begin
      for Child of Children (Request_Tag) loop
         if Child.Kind_Id = Child_Arg
           and then Exists_Type_Attribute (Child.Arg_Tag.all)
           and then Type_Attribute (Child.Arg_Tag.all) = Type_New_Id
         then
            return True;
         end if;
      end loop;

      return False;
   end Is_New_Id_Argument_Present;

   function Is_Interface_Specified
     (Request_Tag : aliased Wayland_XML.Request_Tag) return Boolean is
   begin
      for Child of Children (Request_Tag) loop
         if Child.Kind_Id = Child_Arg
           and then Exists_Type_Attribute (Child.Arg_Tag.all)
           and then Type_Attribute (Child.Arg_Tag.all) = Type_New_Id
           and then Exists_Interface_Attribute (Child.Arg_Tag.all)
         then
            return True;
         end if;
      end loop;

      return False;
   end Is_Interface_Specified;

   function Find_Specified_Interface
     (Request_Tag : aliased Wayland_XML.Request_Tag) return String is
   begin
      for Child of Children (Request_Tag) loop
         if Child.Kind_Id = Child_Arg
           and then Exists_Type_Attribute (Child.Arg_Tag.all)
           and then Type_Attribute (Child.Arg_Tag.all) = Type_New_Id
           and then Exists_Interface_Attribute (Child.Arg_Tag.all)
         then
            return Interface_Attribute (Child.Arg_Tag.all);
         end if;
      end loop;

      raise Interface_Not_Found_Exception;
   end Find_Specified_Interface;

   function Interface_Ptr_Name
     (Interface_Tag : Wayland_XML.Interface_Tag) return String is
   begin
      return Adaify_Name (Name (Interface_Tag) & "_Ptr");
   end Interface_Ptr_Name;

   function Is_Request_Destructor
     (Request_Tag : aliased Wayland_XML.Request_Tag) return Boolean is
      Result : Boolean := False;

      V : Wayland_XML.Request_Child_Vectors.Vector;
   begin
      for Child of Children (Request_Tag) loop
         if Child.Kind_Id = Child_Arg then
            V.Append (Child);
         end if;
      end loop;

      if Exists_Type_Attribute (Request_Tag)
        and then Type_Attribute (Request_Tag) = "destructor"
        and then Name (Request_Tag) = "destroy"
        and then V.Length = 0
      then
         Result := True;
      end if;

      return Result;
   end Is_Request_Destructor;

   function Exists_Destructor
     (Interface_Tag : aliased Wayland_XML.Interface_Tag) return Boolean is
      Result : Boolean := False;
   begin
      for Child of Children (Interface_Tag) loop
         case Child.Kind_Id is
            when Child_Dummy =>
               null;
            when Child_Description =>
               null;
            when Child_Request =>
               if Is_Request_Destructor (Child.Request_Tag.all) then
                  Result := True;
                  exit;
               end if;
            when Child_Event =>
               null;
            when Child_Enum =>
               null;
         end case;
      end loop;

      return Result;
   end Exists_Destructor;

   function Exists_Any_Event_Tag
     (Interface_Tag : aliased Wayland_XML.Interface_Tag) return Boolean is
      Result : Boolean := False;
   begin
      for Child of Children (Interface_Tag) loop
         case Child.Kind_Id is
            when Child_Dummy =>
               null;
            when Child_Description =>
               null;
            when Child_Request =>
               null;
            when Child_Event =>
               Result := True;
               exit;
            when Child_Enum =>
               null;
         end case;
      end loop;

      return Result;
   end Exists_Any_Event_Tag;

   function Make (Text : String) return Interval_Identifier is
      Interval : Xml_Parser_Utils.Interval := (First => 1, Last => 0);

      P           : Integer := Text'First;
      Prev_P      : Integer := P;
      Prev_Prev_P : Integer;
      CP          : Aida.UTF8.Code_Point;

      Is_Previous_New_Line : Boolean := False;
   begin
      return This : Interval_Identifier do
         while
           Aida.UTF8.Is_Valid_UTF8_Code_Point (Source => Text, Pointer => P)
         loop
            Prev_Prev_P := Prev_P;

            Prev_P := P;
            Aida.UTF8.Get (Source => Text, Pointer => P, Value => CP);

            if CP = 10 then
               if Prev_P > Text'First then
                  if not Is_Previous_New_Line then
                     Interval.Last := Prev_Prev_P;
                     This.My_Intervals.Append (Interval);
                  else
                     Interval := (First => 1, Last => 0);
                     This.My_Intervals.Append (Interval);
                  end if;
               end if;

               Is_Previous_New_Line := True;
            elsif CP = 13 then
               Is_Previous_New_Line := True;
            else
               if Is_Previous_New_Line then
                  Interval.First := Prev_P;
               end if;

               Is_Previous_New_Line := False;
            end if;
         end loop;
      end return;
   end Make;

   function Remove_Tabs (Text : String) return String is
      S : Ada.Strings.Unbounded.Unbounded_String;

      P : Integer := Text'First;

      CP : Aida.UTF8.Code_Point;
   begin
      while Aida.UTF8.Is_Valid_UTF8_Code_Point (Text, P) loop
         Aida.UTF8.Get (Source => Text, Pointer => P, Value => CP);

         if CP /= 9 then
            Ada.Strings.Unbounded.Append (S, Aida.UTF8.Image (CP));
         else
            Ada.Strings.Unbounded.Append (S, "   ");
         end if;

      end loop;

      return To_String (S);
   end Remove_Tabs;

   function Exists_Reference_To_Enum
     (Protocol_Tag   : aliased Wayland_XML.Protocol_Tag;
      Interface_Name : String;
      Enum_Name      : String) return Boolean
   is
      Exists : Boolean := False;

      Searched_For : constant String := Interface_Name & "." & Enum_Name;

      procedure Handle_Interface
        (Interface_Tag : aliased Wayland_XML.Interface_Tag)
      is
         procedure Handle_Request
           (Request_Tag : aliased Wayland_XML.Request_Tag)
         is
            procedure Handle_Arg (Arg_Tag : Wayland_XML.Arg_Tag) is
            begin
               if
                 Exists_Type_Attribute (Arg_Tag) and then
                 Type_Attribute (Arg_Tag) = Type_Unsigned_Integer and then
                 Exists_Enum (Arg_Tag) and then
                 Enum (Arg_Tag) = Searched_For
               then
                  Exists := True;
               end if;
            end Handle_Arg;

         begin
            for Child of Children (Request_Tag) loop
               case Child.Kind_Id is
                  when Child_Dummy       => null;
                  when Child_Description => null;
                  when Child_Arg         =>
                     Handle_Arg (Child.Arg_Tag.all);
               end case;

               if Exists then
                  exit;
               end if;
            end loop;
         end Handle_Request;

      begin
         for Child of Children (Interface_Tag) loop
            case Child.Kind_Id is
               when Child_Dummy   => null;
               when Child_Description => null;
               when Child_Request => Handle_Request (Child.Request_Tag.all);
               when Child_Event   => null;
               when Child_Enum    => null;
            end case;

            if Exists then
               exit;
            end if;
         end loop;
      end Handle_Interface;

   begin
      for Child of Children (Protocol_Tag) loop
         case Child.Kind_Id is
            when Child_Dummy =>
               null;
            when Child_Copyright =>
               null;
            when Child_Interface =>
               Handle_Interface (Child.Interface_Tag.all);
         end case;

         if Exists then
            exit;
         end if;
      end loop;

      return Exists;
   end Exists_Reference_To_Enum;

end Xml_Parser_Utils;
