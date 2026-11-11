
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	ParametersStructure = GetParameters(Parameters);
	FillPropertyValues(ThisForm, ParametersStructure);
	
	FiscalizationIsAvailable = RetailSalesServerCall.FiscalizationIsAvailable();
	
	UpdateFiscalEquipmentHyperlink();
	
	SetVisibilityAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If ForceCloseTheForm Then
		Return;
	EndIf;
	
	If Modified And Not SaveParameters And Not Exit Then
		
		Cancel = True;
		
		ButtonsList = New ValueList();
		ButtonsList.Add("Close", NStr("vi = 'Đóng';
										|ru = 'Закрыть';
										|en = 'Close'; fa = 'بستن';
										|it = 'Chiudere';
										|pl = 'Zamknij';
										|tr = 'Kapat'"));
		ButtonsList.Add("NotClose", NStr("vi = 'Không đóng';
										|ru = 'Не закрывать';
										|en = 'Do not close'; fa = 'بسته نشود';
										|it = 'Non chiudere';
										|pl = 'Nie zamykaj';
										|tr = 'Kapatmayın'"));
		
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			NStr("vi = 'Các thông số đã được thay đổi. Đóng mà không lưu cài đặt?';
				|ru = 'Параметры были изменены. Закрыть без сохранения параметров?';
				|en = 'Parameters were changed. Close without saving the parameters?'; fa = 'Parameters were changed. Close without saving the parameters?';
				|it = 'I parametri sono stati modificati. Chiudere  senza salvare i parametri?';
				|pl = 'Parametry zostały zmienione. Zamknij bez zapisywania parametrów?';
				|tr = 'Parametreler değiştirildi. Parametreleri kaydetmeden kapatılsın mı?'"),
			ButtonsList);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(UserAnswer, AdditionalParameters) Export
	
	If UserAnswer = "NotClose" Then
		
		SaveParameters = False;
		
	ElsIf UserAnswer = "Close" Then
		
		ForceCloseTheForm = True;
		SaveParameters = False;
		Close();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CreateSalesDocumentOnChange(Item)
	
	SetVisibilityAvailability(ThisForm);
	
EndProcedure

&AtClient
Procedure CreateCashAccountReceiptNoteOnChange(Item)

	SetVisibilityAvailability(ThisForm);

EndProcedure

&AtClient
Procedure IssueAFiscalReceiptOnChange(Item)

	SetVisibilityAvailability(ThisForm);

EndProcedure

&AtClient
Procedure FiscalEquipmentNavigationLinkProcessing(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	OpenForm("DataProcessor.PreviewReceipt.Form.ErrorOfCREConnection", New Structure("NotToOutputError", True));
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	SaveParameters = True;
	Close(GetParameters(ThisForm));
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function GetParameters(Source)
	
	ParametersStructure = New Structure();
	
	ParametersStructure.Insert("ObjectKey",                      Source.ObjectKey);
	ParametersStructure.Insert("Organization",                      Source.Organization);
	ParametersStructure.Insert("Warehouse",                            Source.Warehouse);
	ParametersStructure.Insert("InvoiceStatus",               Source.InvoiceStatus);
	ParametersStructure.Insert("NoteState",                  Source.NoteState);
	ParametersStructure.Insert("TheDesignSettingsAreSaved",     Source.TheDesignSettingsAreSaved);
	
	ParametersStructure.Insert("PrintCustomerInvoiceWorksAndServices",      Source.PrintCustomerInvoiceWorksAndServices);
	ParametersStructure.Insert("PrintCustomerInvoice",   Source.PrintCustomerInvoice);
	ParametersStructure.Insert("PrintCashAccountReceiptNote",   Source.PrintCashAccountReceiptNote);
	ParametersStructure.Insert("PrintTheTransferOfGoodsToBailee", Source.PrintTheTransferOfGoodsToBailee);
	ParametersStructure.Insert("CreateSalesDocument",         Source.CreateSalesDocument);
	ParametersStructure.Insert("CreateCashAccountReceiptNote",  Source.CreateCashAccountReceiptNote);
	ParametersStructure.Insert("IssueAFiscalReceipt",           Source.IssueAFiscalReceipt);
	ParametersStructure.Insert("DoNotOpenFormOfCreatedDocument", Source.DoNotOpenFormOfCreatedDocument);
	
	Return ParametersStructure;
	
EndFunction

&AtClientAtServerNoContext
Procedure HandleFlagChange(Attribute, DependentElement, DependentAttribute  = Undefined)
	
	DependentElement.Enabled = Attribute;
	If Not Attribute And DependentElement <> Undefined Then
		DependentAttribute = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityAvailability(Form)
	ThisIsTransferToRecycling = ThisIsTransferToRecycling(Form.ObjectKey);
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.PrintSale,
		Form.PrintCustomerInvoice);
		
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.PrintTransfer,
		Form.PrintTheTransferOfGoodsToBailee);
	
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.PrintCertificate,
		Form.PrintCustomerInvoiceWorksAndServices);
		
	
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.DoNotOpenFormOfCreatedDocument,
		Form.DoNotOpenFormOfCreatedDocument);

	ThereIsRightToCreateICO =
		Not ThisIsTransferToRecycling And
		ThereIsRightToCreateICO();
	Form.Items.CreateCashAccountReceiptNote.Visible = ThereIsRightToCreateICO;
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.CreateCashAccountReceiptNote,
		Form.CreateCashAccountReceiptNote);
		
	Form.Items.PrintCashAccountReceiptNote.Visible = ThereIsRightToCreateICO;
	HandleFlagChange(
		Form.CreateCashAccountReceiptNote,
		Form.Items.PrintCashAccountReceiptNote,
		Form.PrintCashAccountReceiptNote);
	If ThisIsTransferToRecycling Then
		
		Form.Items.PrintTransfer.Visible   = False;
		Form.Items.PrintSale.Visible = False;
		Form.Items.PrintCertificate.Visible        = False;
		
	EndIf;
	Form.Items.FiscalizationGroup.Visible =
		Not ThisIsTransferToRecycling And
		Form.FiscalizationIsAvailable;
	
	Form.Items.IssueAFiscalReceipt.Visible = Form.Items.FiscalizationGroup.Visible;
	HandleFlagChange(
		Form.CreateSalesDocument,
		Form.Items.IssueAFiscalReceipt,
		Form.IssueAFiscalReceipt);
		
	Form.Items.SettingsForConnectedHardware.Visible = Form.IssueAFiscalReceipt;
	
EndProcedure

&AtServerNoContext
Function ThereIsRightToCreateICO()
	
	Return AccessRight("Insert",Metadata.Documents.CashAccountReceiptNote);
	
EndFunction

&AtServer
Procedure UpdateFiscalEquipmentHyperlink()
	
	SettingsForConnectedHardware = New FormattedString(NStr("vi = 'Tùy chỉnh';
															|ru = 'Настройка';
															|en = 'Setting'; fa = 'تنظیم';
															|it = 'Impostazione';
															|pl = 'Konfiguracja';
															|tr = 'Ayarlar'"),, 
		StyleColors.HyperlinkColor,, "ConfigureHardware_");
	
EndProcedure
&AtClientAtServerNoContext
Function ThisIsTransferToRecycling(ObjectKey)
	
	Return Not StrFind(ObjectKey, "DocumentsOfTransferToTollingAll2_5") = 0;
	
EndFunction
#EndRegion
