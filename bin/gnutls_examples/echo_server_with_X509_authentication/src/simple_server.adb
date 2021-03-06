with Ada.Text_IO;
with GnuTLS.Certificate_Credentials;
with GnuTLS.X509;

package body Simple_Server is

   use all type GnuTLS.X509.Set_Trust_CAs_File_Result_Kind_Id;
   use all type GnuTLS.X509.Set_CRL_File_Result_Kind_Id;
   use all type GnuTLS.Success_Flag;


   System_Certificates_File : constant String
     := "/etc/ssl/certs/ca-certificates.crt";
   --  A long list of all of your trusted CA's concatenated together
   --
   --  On Linux there is a command called "update-ca-certificates":
   --  update-ca-certificates is a program that updates the directory
   --  /etc/ssl/certs to hold SSL certificates and generates
   --  ca-certificates.crt, a concatenated single-file list of certificates.
   --
   --  It reads the file /etc/ca-certificates.conf. Each line gives a pathname
   --  of a CA certificate under /usr/share/ca-certificates that
   --  should be trusted. Lines that begin with "#" are comment lines
   --  and thus ignored. Lines that begin with "!" are deselected,
   --  causing the deactivation of the CA certificate in question.
   --  Certificates must have a .crt extension in order to be included by
   --  update-ca-certificates.
   --
   --  Furthermore all certificates with a .crt extension found below
   --  /usr/local/share/ca-certificates are also included
   --  as implicitly trusted.

   -- The following certificate is taken from:
   --
   --    http://fm4dd.com/openssl/certexamples.htm
   --

   procedure Run is

      procedure Initialize_GnuTLS;
      procedure Allocate_Credentials;
      procedure Set_X509_Trust_File;
      procedure Set_X509_Crl_File;
      procedure Set_Key_File;

      procedure Initialize_GnuTLS is

         procedure Handle_Failure_Of_Initialization is
         begin
            Ada.Text_IO.Put_Line ("GnuTLS initialization error");
         end Handle_Failure_Of_Initialization;

         procedure Initialize is new GnuTLS.Initialize_GnuTLS
           (Handle_Success => Allocate_Credentials,
            Handle_Failure => Handle_Failure_Of_Initialization);

      begin
         Initialize;
      end Initialize_GnuTLS;

      Credentials : GnuTLS.Certificate_Credentials.Credentials;

      procedure Allocate_Credentials is

         procedure Handle_Failure_Of_Credentials_Allocation is
         begin
            Ada.Text_IO.Put_Line ("Allocation of credentials failed");
         end Handle_Failure_Of_Credentials_Allocation;

         procedure Allocate is
           new GnuTLS.Certificate_Credentials.Allocate_Credentials
             (Handle_Success => Set_X509_Trust_File,
              Handle_Failure => Handle_Failure_Of_Credentials_Allocation,
              This           => Credentials'Access);

      begin
         Allocate;
      end Allocate_Credentials;

      procedure Set_X509_Trust_File is
         Result : GnuTLS.X509.Set_Trust_CAs_File_Result
           := GnuTLS.X509.Set_Trust_CAs_File
             (Credentials => Credentials,
              Name        => System_Certificates_File,
              Format      => GnuTLS.X509.PEM_Text_Format);
      begin
         if Result.Kind_Id = Set_Trust_CAs_File_Success then
            Set_X509_Crl_File;
         else
            Ada.Text_IO.Put_Line ("Failed to set trust file");
         end if;
      end Set_X509_Trust_File;

      --  Add instruction on how to generate crl.der.
      procedure Set_X509_Crl_File is
         Result : GnuTLS.X509.Set_CRL_File_Result
           := GnuTLS.X509.Set_CRL_File
             (Credentials => Credentials,
              Name        => "crl.der",
              Format      => GnuTLS.X509.DER_Binary_Format);
      begin
         if Result.Kind_Id = Set_CRL_File_Success then
            Set_Key_File;
         else
            Ada.Text_IO.Put_Line ("Set X509 Crl file failed");
         end if;
      end Set_X509_Crl_File;

      procedure Set_Key_File is
         Flag : GnuTLS.Success_Flag
           := GnuTLS.X509.Set_Key_File
             (Credentials      => Credentials,
              Certificate_File => "cert.pem",
              Key_File         => "key.pem",
              Format           => GnuTLS.X509.PEM_Text_Format);
      begin
         if Flag = Success then
            Ada.Text_IO.Put_Line ("succ");
         else
            Ada.Text_IO.Put_Line ("Set key file failed");
         end if;
      end Set_Key_File;

   begin
      Ada.Text_IO.Put_Line ("Helo");
      Initialize_GnuTLS;
   end Run;

end Simple_Server;
