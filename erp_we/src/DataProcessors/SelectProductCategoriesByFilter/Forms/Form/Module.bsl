#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.UUID = Undefined Then
		Raise NStr("vi = 'Xem xét mở bộ xử lý chỉ từ biểu mẫu của đối tượng.';
					|ru = 'Предусмотрено открытие обработки только из форм объектов.';
					|en = 'Data processor can be opened only from object forms.'; fa = 'Data processor can be opened only from object forms.';
					|it = 'Viene fornita l''apertura dell''elaborazione solo dalle forme degli oggetti.';
					|pl = 'Przewidziano otwarcie przetwarzania tylko z form obiektów.';
					|tr = 'İşleme sadece nesne formlarından açılır.'");
	EndIf;
	
	CalledFormID = Parameters.UUID;
	
	If Parameters.Property("KeepRecordsOfQualityCertificates") Then
		KeepRecordsOfQualityCertificates = True;
	EndIf;
	
	LoadDefaultSelectionSettings();

	If ValueIsFilled(Parameters.Title) Then
		AutoTitle = False;
		Title = Parameters.Title;
	EndIf;
	If ValueIsFilled(Parameters.TransferButtonTitle) Then
		Commands.MoveToDocument.Title = Parameters.TransferButtonTitle;
		Commands.MoveToDocument.ToolTip = Parameters.TransferButtonTitle;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not ClosingInProgress And Not MoveToDocument And Object.ProductCategories.Count() > 0 Then
		
		Cancel = True;
		ShowQueryBox(New CallbackDescription("BeforeCloseCompletion", ThisObject), NStr("vi = 'Chưa chuyển hàng hóa đã chọn vào chứng từ. Chuyển?';
																						|ru = 'Подобранные товарные категории не перенесены в документ. Перенести?';
																						|en = 'Picked product categories were not transferred to the document. Transfer?'; fa = 'Picked product categories were not transferred to the document. Transfer?';
																						|it = 'Le categorie di prodotti selezionate non vengono trasferite nel documento. Trasferire?';
																						|pl = 'Dobrane kategorie produktu nie zostały przeniesione do dokumentu. Przenieść?';
																						|tr = 'Seçilen ürün kategorileri belgeye transfer edilmedi. Transfer et?'"), QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	UserAnswer = QuestionResult;
	
	If UserAnswer = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
	ElsIf UserAnswer = DialogReturnCode.Yes Then
		MoveToDocument = True;
		ClosingInProgress = True;
		AddressOfProductCategoriesInStorage = PutItInTemporaryStorageOnServer();
		Close(AddressOfProductCategoriesInStorage);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	AddressOfProductCategoriesInStorage = PutItInTemporaryStorageOnServer();
	Close(AddressOfProductCategoriesInStorage);
	
EndProcedure

&AtClient
Procedure FillInTheProductCategoryTable_3(Command)
	
	QueryText = NStr("vi = 'Khi điền lại, sẽ mất tất cả dữ liệu đã nhập thủ công, tiếp tục?';
					|ru = 'При перезаполнении все введенные вручную данные будут потеряны, продолжить?';
					|en = 'During repopulation all information entered manually will be lost, continue?'; fa = 'During repopulation all information entered manually will be lost, continue?';
					|it = 'Quando si ricompila, tutti i dati inseriti manualmente andranno persi, continuare?';
					|pl = 'Przy ponownym wypełnieniu wszystkie ręcznie wprowadzone dane zostaną utracone, kontynuować?';
					|tr = 'Yeniden doldurma sırasında manuel olarak girilen tüm veriler kaybolacaktır, devam edilsin mi?'");
	ShowQueryBox(New CallbackDescription("FillInTheProductCategoryTable_3Completion", ThisObject), QueryText, QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure FillInTheProductCategoryTable_3Completion(QuestionResult, AdditionalParameters) Export
    
    If Object.ProductCategories.Count() = 0 Or DialogReturnCode.Yes = QuestionResult Then
        FillInTableOfProductCategoriesOnServer();
    EndIf;

EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Function SettingsStructure()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("RequiredFields"   , New Array); //
	SettingsStructure.Insert("DataParameters"    , New Structure);
	SettingsStructure.Insert("SettingsComposer", Undefined); // Filter
	SettingsStructure.Insert("NameOfDataLayoutSchemaTemplate" , Undefined);
	SettingsStructure.Insert("KeepRecordsOfQualityCertificates" , KeepRecordsOfQualityCertificates);
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Object.ProductCategories.Unload(), CalledFormID);
	
EndFunction

&AtServer
Procedure FillInTableOfProductCategoriesOnServer(CheckFilling = True)
	
	// The fields required for output to the table of product categories on the form.
	SettingsStructure = SettingsStructure();
	
	SettingsStructure.RequiredFields.Add("ProductCategory");
	
	SettingsStructure.SettingsComposer = SettingsComposer;
	SettingsStructure.NameOfDataLayoutSchemaTemplate = "Template";
	
	Object.ProductCategories.Clear();
	
	// Loading the generated list of product categories.
	ResultStructure1 = DataProcessors.SelectProductCategoriesByFilter.PrepareDataStructure(SettingsStructure);
	For Each TSRow In ResultStructure1.TableOfProductCategories Do
		
		NewRow = Object.ProductCategories.Add();
		FillPropertyValues(NewRow, TSRow);
		
	EndDo;
	
	Items.ProductCategories.Refresh();
	
EndProcedure

&AtServer
Procedure LoadDefaultSelectionSettings()
	
	DataCompositionSchema = DataProcessors.SelectProductCategoriesByFilter.GetTemplate("Template");
	
	SettingsComposer.Initialize(
		New DataCompositionAvailableSettingsSource(PutToTempStorage(DataCompositionSchema, ThisForm.UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	UseProductRange = GetFunctionalOption("UseProductRange");
	If UseProductRange Then
		DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "ProductRangeAsOfDate", CurrentSessionDate());
	EndIf;
	If KeepRecordsOfQualityCertificates Then
		DataCompositionClientServer.SetParameter(SettingsComposer.Settings, "KeepRecordsOfQualityCertificates", True);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Initialize

ClosingInProgress = False;

#EndRegion