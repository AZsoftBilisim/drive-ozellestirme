#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Attributes = PeripheralsReceiptPrinters.FiscalOperationData(Record.DocumentBasis, Record.RecordID);
	If Attributes <> Undefined Then
		XMLMessageText = Attributes.XMLData1.Get();
	EndIf;
	
	Items.DocumentToBeCorrected.Visible = Not IsBlankString(Record.DocumentToBeCorrected);
	
	If ValueIsFilled(XMLMessageText) 
		And (Attributes.DocumentType = Enums.TypesOfCREFiscalDocuments.SALESSLIP 
		Or Attributes.DocumentType = Enums.TypesOfCREFiscalDocuments.AdjustmentSalesSlip)
	Then
		Items.Pages.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
		Items.More.Visible = True;          
		
		FormattingOptions = New XMLWriterSettings("UTF-8", "1.0", True, True, "  ");
		Try
			XMLText.SetText(FormatXMLCParameters(XMLMessageText, FormattingOptions));
			CommonParameters = PeripheralsReceiptPrinters.LoadFiscalizationDataFromXML(XMLMessageText);
		Except
			CommonCEL.MessageToUser(NStr("vi = 'Lỗi kết nhập dữ liệu.';
										|ru = 'Ошибка загрузки данных.';
										|en = 'Data import error.'; fa = 'Data import error.';
										|it = 'Data import error.';
										|pl = 'Data import error.';
										|tr = 'Veri yükleme hatası.'"));  
			Return;
		EndTry; 
		
		CommonParameters.DateTime = Attributes.Date;
		If ValueIsFilled(CommonParameters.BuyerEmail) Then
			Email = CommonParameters.BuyerEmail;
		Else
			Email = EmptyMailString();
		EndIf;
		
		ReceiptWidth = 42;
		Template = FiscalDocumentTemplates.SalesSlipTemplate(ReceiptWidth, CommonParameters, Attributes);
		FiscalDocumentTemplates.GenerateDocumentUsingTemplate(Template);
		SpreadsheetDocument = FiscalDocumentTemplates.OutputAsTabularDocument(Template);
		
	Else
		Items.Presentation2.Visible = False;
		Items.XML.Visible = False;
		Items.More.Visible = False;
	EndIf;
	
	If CommonCEL.MarkingIsUsed() Then
	Else
		Items.KMCheck.Visible = False;
	EndIf;
	
	Items.FormMessageToTechSupport.Visible = CommonCEL.UsedMessagesToTechnicalSupportService()
			And CommonCELInternalServerCall.AuthenticationDataOfOnlineSupportUserFilled();
	
	EquipmentManagerServerCallOverridable.InstanceFiscalOperationsWhenCreatedOnServer(Record, ThisForm, Cancel,  Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If CommonCELClient.UsedMessagesToTechnicalSupportService() Then
		MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
		Items.FormMessageToTechSupport.Visible
			= MessageModuleToBPOTechnicalSupportServiceClient.SendMessagesToTechnicalSupport();
	EndIf;
		
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// Calling BSP
	// Standard subsystems.Access managementreferences
	If CommonCEL.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = CommonCEL.CommonModule("AccessManagement");
		ModuleAccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	EndIf;
	// The end of the standard subsystem.Access managementreferences
	// The end of the BSP Challenge
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Calling BSP
	// Standard subsystems.Access managementreferences
	If CommonCEL.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = CommonCEL.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// The end of the standard subsystem.Access managementreferences
	// The end of the BSP Challenge
	
EndProcedure

&AtClient
Procedure URLProcessing(FormattedStringURL, StandardProcessing)
	
	EquipmentManagerClientOverridable.RecordFormFiscalOperationsNavigationLinkProcessing(
		Record, ThisForm, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServerNoContext
Procedure SendElectronicReceiptOnServer(ReceiptParameters, MessageText, BuyerEmail, BuyerNumber)
	
	ElectronicReceiptMailingModule = CommonCEL.CommonModule("ElectronicCashReceiptMailout");
	ElectronicReceiptMailingModule.SendElectronicReceipt(
			ReceiptParameters,
			MessageText, 
			BuyerEmail,
			BuyerNumber);
			
EndProcedure

&AtClient
Procedure ToSendByEmail(Command)
	
	If Email = EmptyMailString() Then   
		CommonCELClient.MessageToUser(NStr("vi = 'Chưa chỉ ra E-mail.';
											|ru = 'Электронная почта не указана.';
											|en = 'Email is not specified.'; fa = 'Email is not specified.';
											|it = 'Posta elettronica non indicata.';
											|pl = 'Nie podano poczty elektronicznej.';
											|tr = 'E-posta belirtilmemiş.'"));
		Return;
	EndIf;
	
	If CommonCELClient.ElectronicCashReceiptMailoutIsUsed() Then
		ReceiptParameters = New Structure();
		ReceiptParameters.Insert("KKTReceiptNumber", Record.CashRegisterReceiptNumber);
		ReceiptParameters.Insert("IDOfFiscalRecord", Record.RecordID);
		MessageText = "";
		SendElectronicReceiptOnServer(
			ReceiptParameters,
			MessageText, 
			Email,
			"");
		CommonCELClient.MessageToUser(NStr("vi = 'Đã gửi phiếu điện tử.';
											|ru = 'Электронный чек отправлен.';
											|en = 'Electronic receipt is sent.'; fa = 'Electronic receipt is sent.';
											|it = 'Scontrino elettronico inviato.';
											|pl = 'Paragon elektroniczny został wysłany.';
											|tr = 'E-makbuz gönderildi.'"));
	EndIf;
		
EndProcedure

&AtClient
Procedure SavePDF(Command)
	
	// APK: 1348-off BSP may not be used
	Notification = New CallbackDescription("SavePDF_FileSelectionDialog", ThisObject);
	Dialog = New FileDialog(FileDialogMode.Save);
	Dialog.DefaultExt = "pdf";
	Dialog.Filter = "Files PDF (*.pdf)|*.pdf|All files|*.*";
	Dialog.Show(Notification);
	// APK: 1348-on
	
EndProcedure

&AtClient
Procedure SavePDF_FileSelectionDialog(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FileName = Result[0];
	SpreadsheetDocument.BeginWriting(New CallbackDescription("SavePDF_End", ThisObject), FileName, SpreadsheetDocumentFileType.PDF);

EndProcedure

&AtClient
Procedure SavePDF_End(Result, AdditionalParameters) Export
	
	If Not Result Then
		CommonCELClient.MessageToUser(NStr("vi = 'Không thể ghi lại tệp.';
											|ru = 'Не удалось записать файл.';
											|en = 'Cannot save the file.'; fa = 'Cannot save the file.';
											|it = 'Non è stato possibile registrare il file.';
											|pl = 'Nie udało się zapisać pliku.';
											|tr = 'Dosya kaydedilemedi.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure PrintingCopyOfReceipt(Command)

	OperationParametersList = PeripheralsReceiptPrintersClientServer.ParametersPrintCopyOfReceipt();  
	OperationParametersList.FiscalFlag = Record.FiscalFlag;     
	OperationParametersList.Hardware = False;
	OperationParametersList.ReceiptNumber = Record.CashRegisterReceiptNumber;   
	
	Enabled = False;
	
	NotificationOnCompletion = New CallbackDescription("PrintingCopyOfReceipt_Completion", ThisObject);
	PeripheralsReceiptPrintersClient.StartPrintingCopyOfReceipt(NotificationOnCompletion, UUID, Undefined, OperationParametersList);
	
EndProcedure

&AtClient
Procedure PrintingCopyOfReceipt_Completion(ExecutionResult, Var_Parameters) Export
	
	Enabled = True;
	
	ClearMessages();
	
	If Not ExecutionResult.Result Then
		MessageText = ExecutionResult.ErrorDescription;
		CommonCELClient.MessageToUser(MessageText);
	EndIf; 
	
EndProcedure

#EndRegion                 

#Region EventHandlersForFormElements

&AtClient
Procedure MailAddrClick(Item, StandardProcessing)    
	
	StandardProcessing = False;
	String = ?(Email = EmptyMailString(), "", Email);;
	Notification = New CallbackDescription("MailAddrClickCompletion", ThisObject);
	ShowInputString(Notification, String, NStr("vi = 'E-mail để gửi';
												|ru = 'Электронная почта для отправки';
												|en = 'Email'; fa = 'ایمیل';
												|it = 'Posta elettronica per l''invio';
												|pl = 'Poczta elektroniczna do wysyłki';
												|tr = 'Gönderiler için e-posta'"));  
	
EndProcedure

&AtClient
Procedure MailAddrClickCompletion(String, AdditionalParameters) Export
	
	If String = Undefined Then
		Email = Email;
	Else
		If IsBlankString(String) Then
			Email = EmptyMailString();
		Else
			Email = String;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion                 

#Region Private

// Formats the message text in XML format
//
&AtServer
Function FormatXMLCParameters(XMLMessageText, FormattingOptions)
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLMessageText);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString(FormattingOptions);

	DOMWriter = New DOMWriter;
	DOMWriter.Write(DOMDocument, XMLWriter);
	
	Return XMLWriter.Close();  
	
EndFunction

&AtClientAtServerNoContext
Function EmptyMailString()
	
	Return NStr("vi = '<chưa đặt>';
				|ru = '<не задано>';
				|en = '<not set>'; fa = '<تنظیم نشده>';
				|it = '<non indicato>';
				|pl = '<nie określono>';
				|tr = '<belirlenmedi>'"); 

EndFunction

&AtServerNoContext
Procedure KMCheckListOnGetDataAtServer(TagName, Settings, Rows)
	
	ModuleEquipmentManagerMarking = CommonCEL.CommonModule("EquipmentManagerMarking");
	ModuleEquipmentManagerMarking.WhenReceivingDataFromListOfCRVerificationOperations(TagName, Settings, Rows);
	
EndProcedure

&AtServerNoContext
Function InfoForTechSupport(IDOfFiscalRecord)
	
	Return InformationRegisters.FiscalTransactions.RecordDataForThoseSupport(IDOfFiscalRecord);
	
EndFunction

&AtClient
Procedure MessageToTechSupport(Command)
	
	MessageModuleToBPOTechnicalSupportServiceClient = CommonCELClient.CommonModule("MessagesToTechnicalSupportCELClient");
	MessageParameters = MessageModuleToBPOTechnicalSupportServiceClient.ParametersForSendingErrorMessage();
	MessageParameters.AdditionalData = InfoForTechSupport(Record.RecordID);
	
	MessageParameters.ErrorText = NStr("vi = 'Thông tin về giao dịch ấn định để hỗ trợ kỹ thuật';
										|ru = 'Информация о фискальной операции для тех.поддержки';
										|en = 'Information on the fiscal transaction for technical support'; fa = 'Information on the fiscal transaction for technical support';
										|it = 'Информация о фискальной операции для тех.поддержки';
										|pl = 'Information on the fiscal transaction for technical support';
										|tr = 'Teknik destek için mali işlemle ilgili bilgiler'");
	CallbackDescription = New CallbackDescription("MessageToTechnicalSupportCompletion", ThisObject);
	MessageModuleToBPOTechnicalSupportServiceClient.StartSendingErrorMessage(CallbackDescription, MessageParameters);
	
EndProcedure

&AtClient
Procedure MessageToTechnicalSupportCompletion(Result, AdditionalParameters) Export
	
	If Not IsBlankString(Result.ErrorCode) Then
		CommonCELClient.MessageToUser(Result.ErrorMessage);
	EndIf;
	
EndProcedure 



#EndRegion