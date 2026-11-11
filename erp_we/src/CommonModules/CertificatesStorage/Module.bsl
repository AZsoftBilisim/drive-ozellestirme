////////////////////////////////////////////////////////////////////////////////
// The subsystem "Certificate Store".
//  
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Adds the certificate to the certificate store.
// 
// Parameters:
//   Certificate - BinaryData - certificate file.
//              - String - the address of the certificate file in the temporary storage.
//   StoreType - String, EnumRef.CertificatesStorageType - type of storage to add the certificate to.
//
Procedure Add(Certificate, StoreType) Export

	If TypeOf(StoreType) = Type("String") Then
		StoreType = XMLValue(Type("EnumRef.CertificatesStorageType"), StoreType);
	EndIf;

	AddIncomingParameterVerification(Certificate, StoreType);

	If TypeOf(Certificate) = Type("String") Then
		CertificateBinaryData_ = GetFromTempStorage(Certificate);
	Else
		CertificateBinaryData_ = Certificate;
	EndIf;
		
	CertificateProperties = CryptographyService.GetCertificateProperties(CertificateBinaryData_);
	
	RecordSet = InformationRegisters.CertificatesStorage.CreateRecordSet();
	RecordSet.Filter.StoreType.Set(StoreType);
	RecordSet.Filter.Id.Set(CertificateProperties.Id);
	
	NewRecord = RecordSet.Add();
	NewRecord.StoreType  = StoreType;
	NewRecord.Id = CertificateProperties.Id;	
	NewRecord.StartDate    = CertificateProperties.StartDate;
	NewRecord.EndDate = CertificateProperties.EndDate;
	NewRecord.SerialNumber = Lower(StrReplace(CertificateProperties.SerialNumber, " ", ""));
	NewRecord.Thumbprint     = Lower(StrReplace(CertificateProperties.Thumbprint, " ", ""));
	If CertificateProperties.Subject.Property("CN") Then
		NewRecord.Description  = CertificateProperties.Subject.CN;
	EndIf;

	NewRecord.Certificate = New ValueStorage(CertificateProperties, New Deflation(9));
	
	RecordSet.Write();
	
EndProcedure

// Retrieves certificates from the storage.
// 
// Parameters:
//   StoreType - String, EnumRef.CertificatesStorageType - type of storage to get
//                                                                certificates from.
//                                                                If not filled in, all certificates will be received.
//
// Returns:
//	 Array of FixedStructure - certificate properties:
//    * Version - String - the version of the certificate.
//    * StartDate - Date - date when the certificate started.
//    * EndDate - Date - expiry date of the certificate.
//    * Issuer - FixedStructure - information about the certificate publisher:
//        ** CN - String - commonName 
//        ** O - String - organizationName 
//        ** OU - String - organizationUnitName 
//        ** C - String - countryName 
//        ** ST - String - stateOrProvinceName 
//        ** L - String - localityName 
//        ** E - String - emailAddress 
//        ** SN - String - surname 
//        ** GN - String - givenName 
//        ** T - String - title
//        ** STREET - String - streetAddress
//        ** OGRN - String - OGRN
//        ** OGRNIP - String - OGRNIE
//        ** INN - String - INN (optional)
//        ** INNLE - String - TIN YUL (optional)
//        ** SNILS - String - SNILS
//    * UseToSign - Boolean - specifies whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - specifies whether this certificate can be used for encryption.
//    * Thumbprint - BinaryData - contains the data of the print. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure - Extended Certificate Properties:
//        ** EKU - FixedArray of String - Enhanced Key Usage.
//    * SerialNumber - BinaryData - serial number of the certificate.
//    * Subject - FixedStructure - information about the subject of the certificate:
//        ** CN - String - commonName... etc. composition see Publisher.
//    * Certificate - BinaryData - certificate file in DER encoding.
//    * Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//                               Used to identify the certificate in the cryptography service.
//
Function Get(StoreType = Undefined) Export
		
	If TypeOf(StoreType) = Type("String") Then
		StoreType = XMLValue(Type("EnumRef.CertificatesStorageType"), StoreType);
	EndIf;
	
	If ValueIsFilled(StoreType) Then
		CommonClientServer.CheckParameter(
			"CertificatesStorage.Get", 
			"StoreType",
			StoreType, 
			New TypeDescription("EnumRef.CertificatesStorageType"));
	EndIf;
			
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CertificatesStorage.Certificate,
	|	CertificatesStorage.StoreType
	|FROM
	|	InformationRegister.CertificatesStorage AS CertificatesStorage
	|WHERE
	|	(NOT &UseSelectionByStorageType
	|			OR CertificatesStorage.StoreType = &StoreType)";
	Query.SetParameter("StoreType", StoreType);
	Query.SetParameter("UseSelectionByStorageType", ValueIsFilled(StoreType));
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();	
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	Certificates = New Array;
	While Selection.Next() Do
		Certificates.Add(Selection.Certificate.Get());
	EndDo;
		
	Return Certificates;
		
EndFunction

// Searches for the certificate in the storage.
//
// Parameters:
//   Certificate - Structure - key certificate parameters used for searching:
//                            An imprint or a pair of serial number and Publisher.
//     * Thumbprint - BinaryData - fingerprint certificate.
//                 - String - string representation of the print.
//     * SerialNumber - BinaryData - serial number of the certificate.
//                     - String - string representation of the serial number.
//     * Issuer - Structure - publisher properties
//                - String - string representation of the publisher.
//
// Returns: 
//   Undefined, FixedStructure - certificate not found or properties of the found certificate:
//    * Description - String - name of the certificate.
//    * Version - String - the version of the certificate.
//    * StartDate - Date - date when the certificate started.
//    * EndDate - Date - expiry date of the certificate.
//    * Issuer - FixedStructure - information about the certificate publisher:
//        ** CN - String - commonName; 
//        ** O - String - organizationName; 
//        ** OU - String - organizationUnitName; 
//        ** C - String - countryName; 
//        ** ST - String - stateOrProvinceName; 
//        ** L - String - localityName; 
//        ** E - String - emailAddress; 
//        ** SN - String - surname; 
//        ** GN - String - givenName; 
//        ** T - String - title;
//        ** STREET - String - streetAddress;
//        ** OGRN - String - Bin;
//        ** OGRNIP - String - OGRNIP;
//        ** INN - String -  INN (optional);
//        ** INNLE - String - TIN YUL (optional);
//        ** SNILS - String - SNILS;
//           ...
//    * UseToSign - Boolean - specifies whether this certificate can be used for signing.
//    * UseToEncrypt - Boolean - specifies whether this certificate can be used for encryption.
//    * Thumbprint - BinaryData - contains the data of the print. It is calculated dynamically using the SHA-1 algorithm.
//    * Extensions - FixedStructure -  Extended Certificate Properties:
//        ** EKU - FixedArray of String - Enhanced Key Usage.
//    * SerialNumber - BinaryData - serial number of the certificate.
//    * Subject - FixedStructure - information about the subject of the certificate. Composition see Publisher:
//        ** CN - String - commonName, etc...
//    * Certificate - BinaryData - certificate file in DER encoding.
//    * Id - String - calculated by the key properties of the Publisher and the serial number using the SHA1 algorithm.
//                               Used to identify the certificate in the cryptography service.
//
Function FindCertificate(Certificate) Export
	
	FindCertificateCheckingIncomingParameters(Certificate);
	
	If Certificate.Property("Thumbprint") Then
		Thumbprint = Lower(StrReplace(Certificate.Thumbprint, " ", ""));
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CertificatesStorage.Certificate
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Thumbprint = &Thumbprint";
		Query.SetParameter("Thumbprint", Thumbprint);
	Else
		If TypeOf(Certificate.Issuer) = Type("String") Then
			Issuer = ParsePublisherString(Certificate.Issuer);
		Else
			Issuer = Certificate.Issuer;
		EndIf;
		
		ListOfOIDs = New ValueList;
		For Each KeyValue In Issuer Do
			ListOfOIDs.Add(KeyValue.Value, KeyValue.Key);
		EndDo;
		
		Id = CryptographyServiceInternal.CalculateCertificateID(
			Certificate.SerialNumber, ListOfOIDs);
		
		Query = New Query;
		Query.Text =
		"SELECT ALLOWED
		|	CertificatesStorage.Certificate
		|FROM
		|	InformationRegister.CertificatesStorage AS CertificatesStorage
		|WHERE
		|	CertificatesStorage.Id = &Id";
		Query.SetParameter("Id", Id);		
	EndIf;
	
	SetSafeModeDisabled(True);
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	SetSafeModeDisabled(False);
	
	If Result.IsEmpty() Then
		Return Undefined;
	Else
		Selection = Result.Select();
		Selection.Next();
		
		Return Selection.Certificate.Get();
	EndIf;
	
EndFunction

#EndRegion


#Region Internal

// Returns the certificate data in DER-encoded
// 
// Parameters:
// 	Certificate - BinaryData - certificate data
// 	VerificationChar - String - 
// Returns:
// 	BinaryData - certificate data in DER encoding
// 
Function DERCertificate(Certificate, VerificationChar = "") Export
	
	FileName = GetTempFileName("cer");
	Certificate.Write(FileName);
	
	Text = New TextDocument;
	Text.Read(FileName);
	TextOfCertificate = Text.GetText();
	
	Try
		DeleteFiles(FileName);
	Except
		WriteLogEvent(
			NameOfDeleteFileEvent(),
			EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
	EndTry;
		
	If StrFind(TextOfCertificate, "-----BEGIN CERTIFICATE-----") > 0 Then
		TextOfCertificate = StrReplace(TextOfCertificate, "-----BEGIN CERTIFICATE-----" + VerificationChar, "");
		TextOfCertificate = StrReplace(TextOfCertificate, VerificationChar + "-----END CERTIFICATE-----", "");
		Return Base64Value(TextOfCertificate);
	Else		
		Return Certificate;
	EndIf;
	
EndFunction

#EndRegion


#Region Private
	
Function NameOfDeleteFileEvent()
	
	// @skip-check module-nstr-camelcase - verification error
	Return NStr("vi = 'Kho chứa chứng thư.Xóa tệp';
				|ru = 'Хранилище сертификатов.Удаление файла';
				|en = 'Certificate store.Delete file'; fa = 'Certificate store.Delete file';
				|it = 'Archivio certificati. Eliminazione del file';
				|pl = 'Magazyn certyfikatów.Usuwanie plików';
				|tr = 'Sertifika deposu.Dosya silme'", Common.DefaultLanguageCode());
	
EndFunction

Procedure FindCertificateCheckingIncomingParameters(Certificate)
	
	CommonClientServer.CheckParameter(
		"CertificatesStorage.FindCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("Structure, FixedStructure")
	);
	
	If Certificate.Property("Thumbprint") Then
		TypesOfCertificateProperties = New Structure;
		TypesOfCertificateProperties.Insert("Thumbprint", New TypeDescription("String, BinaryData"));
	Else
		TypesOfCertificateProperties = New Structure;
		TypesOfCertificateProperties.Insert("SerialNumber", New TypeDescription("String, BinaryData"));
		TypesOfCertificateProperties.Insert("Issuer", New TypeDescription("String, Structure, FixedStructure"));
	EndIf;

	CommonClientServer.CheckParameter(
		"CertificatesStorage.FindCertificate", 
		"Certificate",
		Certificate, 
		New TypeDescription("Structure, FixedStructure"),
		TypesOfCertificateProperties
	);
	
EndProcedure

Function ParsePublisherString(PublisherByLine)
	
	Components = New Map;
	
	SubstringForParsing = PublisherByLine;
	
	IndexIsEqualTo = StrFind(SubstringForParsing, "=", SearchDirection.FromEnd);
	While IndexIsEqualTo Do
		Value = Mid(SubstringForParsing, IndexIsEqualTo + 1);
		If Right(Value, 1) = "," Then
			StringFunctionsClientServer.DeleteLastCharInString(Value);
		EndIf;
		
		SubstringForParsing = Left(SubstringForParsing, IndexIsEqualTo - 1);
		
		CommaIndex = StrFind(SubstringForParsing, ",", SearchDirection.FromEnd);
		If CommaIndex Then
			Var_Key = Mid(SubstringForParsing, CommaIndex + 1);
			SubstringForParsing = Left(SubstringForParsing, CommaIndex);
		Else
			Var_Key = SubstringForParsing;	
		EndIf;
		IndexIsEqualTo = StrFind(SubstringForParsing, "=", SearchDirection.FromEnd);
		
		Components.Insert(TrimAll(Var_Key), TrimAll(Value));
	EndDo;
	
	Return Components;	
	
EndFunction

Procedure AddIncomingParameterVerification(Certificate, StoreType)
		
	CommonClientServer.CheckParameter(
		"CertificatesStorage.Add", 
		"Certificate",
		Certificate, 
		New TypeDescription("BinaryData, String"));
		
	CommonClientServer.CheckParameter(
		"CertificatesStorage.Add", 
		"StoreType",
		StoreType, 
		New TypeDescription("EnumRef.CertificatesStorageType"));
		
	If TypeOf(Certificate) = Type("String") Then
		CommonClientServer.Validate(
			IsTempStorageURL(Certificate),
			NStr("vi = 'Giá trị tham số Сертификат không hợp lệ (đã chỉ ra địa chỉ không phải là địa chỉ kho chứa tạm thời)';
				|ru = 'Недопустимое значение параметра Сертификат (указан адрес, который не является адресом временного хранилища)';
				|en = 'Invalid value of the Certificate parameter (specified address is not a temporary storage address)'; fa = 'Invalid value of the Certificate parameter (specified address is not a temporary storage address)';
				|it = 'Valore del parametro Certificato non disponibile (indicato l''indirizzo che non è quello del deposito temporaneo)';
				|pl = 'Niepoprawna wartość parametru Certyfikat (podany adres nie jest adresem tymczasowego magazynowania)';
				|tr = 'Sertifika parametresi için geçersiz değer (geçici depolama adresi olmayan adres belirtilmiş)'"), 
			"CertificatesStorage.Add");
	EndIf;
	
EndProcedure

#EndRegion