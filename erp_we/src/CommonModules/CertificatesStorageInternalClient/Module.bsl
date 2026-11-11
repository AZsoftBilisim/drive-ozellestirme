////////////////////////////////////////////////////////////////////////////////
// Subsystem "Certificate store (service)".
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Internal

Procedure Add(CallbackOnCompletion, Certificate, StoreType) Export

	ExecutionResult = New Structure("Completed2");
	Try
		CertificatesStorageInternalServerCall.Add(Certificate, StoreType);
		ExecutionResult.Completed2 = True;
	Except
		ExecutionResult.Completed2 = False;
		ExecutionResult.Insert("ErrorInfo", ErrorInfo());
	EndTry;
	
	RunCallback(CallbackOnCompletion, ExecutionResult);
	
EndProcedure

Procedure Get(CallbackOnCompletion, StoreType = Undefined) Export
	
	ExecutionResult = New Structure("Completed2");
	Try
		Certificates = CertificatesStorageInternalServerCall.Get(StoreType);
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificates", Certificates);
	Except
		ExecutionResult.Completed2 = False;
		ExecutionResult.Insert("ErrorInfo", ErrorInfo());
	EndTry;
	
	RunCallback(CallbackOnCompletion, ExecutionResult);
	
EndProcedure

Procedure FindCertificate(CallbackOnCompletion, Certificate) Export
	
	ExecutionResult = New Structure("Completed2");
	Try
		FoundCertificate = CertificatesStorageInternalServerCall.FindCertificate(Certificate);
		ExecutionResult.Completed2 = True;
		ExecutionResult.Insert("Certificate", FoundCertificate);
	Except
		ExecutionResult.Completed2 = False;
		ExecutionResult.Insert("ErrorInfo", ErrorInfo());
	EndTry;
	
	RunCallback(CallbackOnCompletion, ExecutionResult);
	
EndProcedure

#EndRegion