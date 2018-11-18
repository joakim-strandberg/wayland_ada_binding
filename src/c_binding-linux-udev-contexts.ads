limited with C_Binding.Linux.Udev.Monitors;
limited with C_Binding.Linux.Udev.Devices;
limited with C_Binding.Linux.Udev.Queues;
limited with C_Binding.Linux.Udev.Hardware_Databases;

package C_Binding.Linux.Udev.Contexts is

   type Context;

   procedure Acquire_Reference
     (Original  : Contexts.Context;
      Reference : out Contexts.Context) with
     Pre => Contexts.Exists (Original);
   --  Acquire a reference to an existing udev context object.
   --  The reference count to Original goes up by 1.

   procedure Create_Context (Context : out Contexts.Context);
   --  Create udev context object. This reads the udev configuration file,
   --  and fills in the default values.
   --
   --  On success, Context.Exists = True.
   --  On failure, Context.Exists = False.
   --
   --  When successful, the reference count is 1.

   type Context is new Context_Base with private with
     Default_Initial_Condition => not Context.Exists;
   --  Represents a udev context object that may or may not exist.
   --  Before you can do anything with Udev the application must
   --  have a "connection" to Udev. This type represents such a "connection".

   function Exists (Context : Contexts.Context) return Boolean;

   procedure Delete (Context : in out Contexts.Context) with
     Pre  => Context.Exists,
     Post => not Context.Exists;
   --  Delete a udev context object.
   --  The reference count drops by 1.
   --  Once the reference count hits 0,
   --  the context object is destroyed and freed.

   procedure Create_Monitor
     (Context : Contexts.Context;
      Name    : String;
      Monitor : out Monitors.Monitor);
   --  Create a udev monitor object.
   --  On success, Monitor.Exists = True.
   --  On failure, Monitor.Exists = False.

   procedure Create_Device
     (Context       : Contexts.Context;
      Block_Device  : Character;
      Device_Number : Interfaces.Unsigned_64;
      Device        : out Devices.Device);

   procedure Create_Device
     (Context   : Contexts.Context;
      Subsystem : String;
      Sysname   : String;
      Device    : out Devices.Device);

   procedure Create_Device
     (Context : Contexts.Context;
      Id      : String;
      Device  : out Devices.Device);

   procedure Create_Device
     (Context : Contexts.Context;
      Device  : out Devices.Device);

   procedure Create_Queue
     (Context : Contexts.Context;
      Queue   : out Queues.Queue);

   procedure New_Hardware_Database
     (Context  : Contexts.Context;
      Database : out Hardware_Databases.Database);

   function Log_Priority (Context : Contexts.Context) return Integer;

   procedure Set_Log_Priority
     (Context : Contexts.Context;
      Value   : Integer);

   generic
      with procedure Log
        (Context  : Contexts.Context;
         Priority : Integer;
         File     : String;
         Line     : Integer;
         Fn       : String;
         Format   : String);
   package Logging is

      procedure Redirect_Logs (Context : Contexts.Context);

   end Logging;

   generic
      type Data_Type (<>) is limited private;
      type Data_Ptr is not null access all Data_Type;
   package Custom_Data is

      procedure Set_Userdata
        (Context : Contexts.Context;
         Data    : Data_Ptr) with
        Pre => Context.Exists;

      function Get_Userdata
        (Context : Contexts.Context) return Data_Ptr;

   end Custom_Data;

private

   type Context is new Context_Base with null record;

   overriding
   procedure Finalize (Context : in out Contexts.Context);

   function Exists (Context : Contexts.Context) return Boolean is
     (Context.My_Ptr /= null);

end C_Binding.Linux.Udev.Contexts;
