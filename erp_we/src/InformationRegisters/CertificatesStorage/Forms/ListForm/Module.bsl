#Region FormCommandsEventHandlers

#Region ExportCertificate

&AtClient
Procedure ExportCertificate(Command)
	
	CurrentRecord = Items.List.CurrentRow;
	If CurrentRecord <> Undefined Then
		CurrentData = Items.List.CurrentData;
		If CurrentData <> Undefined Then
			CertificateFileName = CurrentData.Description + ".cer";
		Else
			CertificateFileName = "Certificate.cer";
		EndIf;
		Notification = New CallbackDescription("UploadCertificateAfterSearch", 
			ThisObject, New Structure("FileName", CertificateFileName));
		CertificatesStorageClient.FindCertificate(Notification, New Structure("Thumbprint", CurrentData.Thumbprint));
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadCertificateAfterSearch(Result, IncomingContext) Export
	
	If Result.Completed2 And ValueIsFilled(Result.Certificate) Then
		GetFile(PutToTempStorage(Result.Certificate.Certificate), 
			IncomingContext.FileName, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region ImportCertificate

&AtClient
Procedure ImportCertificate(Command)
	
	ToolTipText = NStr("vi = 'Hãy chỉ ra kiểu kho chứa';
						|ru = 'Укажите тип хранилища';
						|en = 'Specify storage type'; fa = 'Specify storage type';
						|it = 'Indica il tipo di repository';
						|pl = 'Określ rodzaj przechowywania';
						|tr = 'Depolama türünü belirtin'");
	CallbackDescription = New CallbackDescription("DownloadCertificateAfterSelectingStorageType", ThisObject);
	ShowInputValue(CallbackDescription, , ToolTipText, Type("EnumRef.CertificatesStorageType"));
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterSelectingStorageType(StoreType, AdditionalParameters) Export
	
	If StoreType <> Undefined Then
		CallbackDescription = New CallbackDescription("DownloadCertificateAfterPlacingFile", ThisObject, StoreType);
		BeginPutFile(CallbackDescription,,, True, UUID);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterPlacingFile(Result, CertificateAddress, SelectedFileName, StoreType) Export
	
	If Result Then
		Notification = New CallbackDescription("DownloadCertificateAfterAddingItToRepository", ThisObject);
		CertificatesStorageClient.Add(Notification, CertificateAddress, StoreType);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadCertificateAfterAddingItToRepository(Result, IncomingContext) Export

	If Result.Completed2 Then
		Items.List.Refresh();
	ElsIf Result.Property("ErrorInfo") Then 
		ShowMessageBox(, ErrorProcessing.BriefErrorDescription(Result.ErrorInfo));		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion