////////////////////////////////////////////////////////////////////////////////
// Subsystem "Certificate store (service)".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Internal

Procedure Add(Certificate, StoreType) Export

	CertificatesStorage.Add(Certificate, StoreType);
	
EndProcedure

// Parameters: 
//  StoreType - See CertificatesStorage.Get.StoreType
// 
// Returns: See CertificatesStorage.Get
Function Get(StoreType = Undefined) Export
	
	Return CertificatesStorage.Get(StoreType);
	
EndFunction

// Parameters: 
//  Certificate - See CertificatesStorage.FindCertificate.Certificate
// 
// Returns: See CertificatesStorage.FindCertificate
Function FindCertificate(Certificate) Export
	
	Return CertificatesStorage.FindCertificate(Certificate);
	
EndFunction

#EndRegion