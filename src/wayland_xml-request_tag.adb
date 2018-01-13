package body Wayland_XML.Request_Tag is

   procedure Set_Name (This    : in out Request_Tag_T;
                       Value   : String;
                       Subpool : Dynamic_Pools.Subpool_Handle)
   is
   begin
      This.My_Name := (Exists => True,
                       Value  => new (Subpool) String'(Value));
   end Set_Name;

   procedure Append_Child (This  : in out Request_Tag_T;
                           Item  : not null Wayland_XML.Description_Tag.Description_Tag_Ptr)
   is
      Child : Child_T := (Child_Description, Item);
   begin
      This.My_Children.Append (Child);
   end Append_Child;

   procedure Append_Child (This  : in out Request_Tag_T;
                           Item  : not null Wayland_XML.Arg_Tag.Arg_Tag_Ptr)
   is
      Child : Child_T := (Child_Arg, Item);
   begin
      This.My_Children.Append (Child);
   end Append_Child;

   procedure Set_Type_Attribute (This    : in out Request_Tag_T;
                                 Value   : String;
                                 Subpool : Dynamic_Pools.Subpool_Handle)
   is
   begin
      This.My_Type_Attribute := (Exists => True,
                                 Value  => new (Subpool) String'(Value));
   end Set_Type_Attribute;

   procedure Set_Since (This  : in out Request_Tag_T;
                        Value : Version_T) is
   begin
      This.My_Since := (Exists => True,
                        Value  => Value);
   end Set_Since;

end Wayland_XML.Request_Tag;
