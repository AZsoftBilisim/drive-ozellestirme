#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Property("DocumentObject") 
		Or Not TypeOf(Parameters.DocumentObject) = Type("FormDataStructure")
		Or Not Parameters.DocumentObject.Property("Ref") Then
		Cancel = True;
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, Parameters.DocumentObject,,"GoodsReceipt");
	GoodsReceipt.Load(Parameters.DocumentObject.GoodsReceipt.Unload());
	
	CustomizeFormDependingOnDocumentType(Parameters.DocumentObject);
	
	If TMCommonUseClientServer.AnExternalUserIsAuthorized() Then
		
		If Parameters.DocumentObject.Status <> Enums.StatusesOfDiscrepancyReport.NotApproved Then
			ReadOnly = True;
		EndIf;
		
		Items.InsuranceCompany.Visible           = False;
		Items.InsuranceCompanyCounterparty.Visible = False;
		
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not ClosingInProgress And Modified And Not SaveParameters Then
		
		SaveParameters = False;
		Notification = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		WarningText = NStr("vi = 'Chi tiết về con dấu của biên bản chênh lệch đã được thay đổi. Chuyển đổi thay đổi?';
							|ru = 'Реквизиты печати акта о расхождениях были изменены. Перенести изменения?';
							|en = 'Attributes for discrepancy report printing were changed. Copy the changes?'; fa = 'Attributes for discrepancy report printing were changed. Copy the changes?';
							|it = 'I requisiti di stampa dell''atto sulle discrepanze sono stati modificati. Trasferire le modifiche?';
							|pl = 'Atrybuty wydruku protokołu o odchyleniu zostały zmienione. Przenieść zmiany?';
							|tr = 'Tutarsızlık raporunun yazdırma öznitelikleri değiştirilmiştir. Değişiklikler kaydedilsin mi?'");
		
		CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit, WarningText);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	ClosingInProgress = True;
	SaveParameters  = True;
	Close();
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	If SaveParameters And Not Exit Then
		
		NotifyChoice(StructureOfReturnedData());
		
	EndIf;

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InsuranceCompanyOnChange(Item)
	InsuranceCompanyWhenChangingOnServer();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If Not ReadOnly Then
		SaveParameters = True;
	EndIf;
	
	Close();
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InsuranceCompanyWhenChangingOnServer()
	
	PartnersAndCounterparties.FillInPartnerSDefaultCounterparty(InsuranceCompany, InsuranceCompanyCounterparty);
	
EndProcedure

&AtServer
Function StructureOfReturnedData()
	
	ReturnStructure = New Structure;
	
	FormAttributes = GetAttributes();
	For Each FormAttribute In FormAttributes Do
		
		ReturnStructure.Insert(FormAttribute.Name, ThisObject[FormAttribute.Name]);
		
	EndDo;
	
	Return ReturnStructure;
	
EndFunction

// Configures the form depending on the document type
// 
// Parameters:
// 	DocumentObject - DocumentObject.DiscrepancyReportFollowingShipment - 
//                 - DocumentObject.DiscrepancyReportFollowingReceipt -
//                 - DocumentObject.DiscrepancyReportFollowingTransfer - the act of discrepancies.
//
&AtServer
Procedure CustomizeFormDependingOnDocumentType(DocumentObject)
	
	HasUpdateRight = False;
	
	If TypeOf(DocumentObject.Ref) = Type("DocumentRef.DiscrepancyReportFollowingShipment") Then
		
		Items.Director.TypeRestriction     = New TypeDescription("String");
		Items.ChiefAccountant.TypeRestriction = New TypeDescription("String");
		Items.Shipper.TypeRestriction = New TypeDescription("String");
		
		HasUpdateRight = AccessRight("Update", Metadata.Documents.DiscrepancyReportFollowingShipment);
		
	ElsIf TypeOf(DocumentObject.Ref) = Type("DocumentRef.DiscrepancyReportFollowingReceipt") Then
		
		Items.Director.TypeRestriction     = New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies");
		Items.ChiefAccountant.TypeRestriction = New TypeDescription("CatalogRef.PersonsResponsibleAndCompanies");
		Items.Shipper.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
		
		HasUpdateRight = AccessRight("Update", Metadata.Documents.DiscrepancyReportFollowingReceipt);
		
	EndIf;
	
	ReadOnly = Not HasUpdateRight;

EndProcedure

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
