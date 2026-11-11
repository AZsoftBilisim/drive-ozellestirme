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
	
	ProcessPassedParameters(Parameters);
	
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                       ThisObject, "SelectedPartners", NStr("vi = 'Đối tác đã chọn';
																|ru = 'Подобранные контрагенты';
																|en = 'Picked counterparties'; fa = 'Picked counterparties';
																|it = 'Controparti abbinati';
																|pl = 'Dobrani kontrahenci';
																|tr = 'Seçilen cari hesaplar'"), UsePartnersAsCounterparties);
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
	                       ThisObject, "PartnersPartners", NStr("vi = 'Đối tác';
																|ru = 'Контрагент';
																|en = 'Counterparty'; fa = 'طرف حساب';
																|it = 'Controparte';
																|pl = 'Counterparty';
																|tr = 'Cari hesap'"), UsePartnersAsCounterparties);
	
	InitializeComposerServer(Undefined);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Not Exit And Not ClosingInProgress And Not MoveToDocument And Partners.Count() > 0 Then
		
		If UsePartnersAsCounterparties Then
			QueryText = NStr("vi = 'Chưa chuyển đối tác đã chọn vào chứng từ. Chuyển?';
							|ru = 'Подобранные контрагенты не перенесены в документ. Перенести?';
							|en = 'Picked counterparties were not transferred to the document. Transfer?'; fa = 'Picked counterparties were not transferred to the document. Transfer?';
							|it = 'Le controparti abbinate non sono trasferite nel docuemnto.Trasferire?';
							|pl = 'Dobrani kontrahenci nie zostali przeniesieni do dokumentu. Przenieść?';
							|tr = 'Seçilen cari hesaplar belgeye aktarılmadı. Transfer et?'");
		Else
			QueryText = NStr("vi = 'Chưa chuyển bạn hàng đã chọn vào chứng từ. Chuyển?';
							|ru = 'Подобранные партнеры не перенесены в документ. Перенести?';
							|en = 'Picked partners were not transferred to the document. Transfer?'; fa = 'Picked partners were not transferred to the document. Transfer?';
							|it = 'I partner abbinati non sono stati trasferiti nel documento.Trasferire?';
							|pl = 'Dobrani partnerzy nie zostali przeniesieni do dokumentu. Przenieść?';
							|tr = 'Seçilen iş ortakları belgeye aktarılmadı. Transfer et?'");
		EndIf;
		
		Cancel = True;
		
		ShowQueryBox(
			New CallbackDescription("BeforeCloseCompletion", ThisObject), 
			QueryText, 
			QuestionDialogMode.YesNoCancel);
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.No Then
		ClosingInProgress = True;
		Close();
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		ClosingInProgress = True;
		MoveToDocument = True;
		AddressOfPartnersInRepository = PutItInTemporaryStorageOnServer();
		Close(AddressOfPartnersInRepository);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	MoveToDocument = True;
	GoodsAddressInStorage = PutItInTemporaryStorageOnServer();
	Close(GoodsAddressInStorage);
	
EndProcedure

&AtClient
Procedure FillInPartnerTable(Command)
	
	QueryText = NStr("vi = 'Khi điền lại, tất cả dữ liệu đã nhập thủ công sẽ mất, tiếp tục?';
					|ru = 'При перезаполнении все введенные вручную данные будут потеряны, продолжить?';
					|en = 'During repopulation all information entered manually will be lost, continue?'; fa = 'During repopulation all information entered manually will be lost, continue?';
					|it = 'Quando si ricompila, tutti i dati inseriti manualmente andranno persi, continuare?';
					|pl = 'Przy ponownym wypełnieniu wszystkie ręcznie wprowadzone dane zostaną utracone, kontynuować?';
					|tr = 'Yeniden doldurma sırasında manuel olarak girilen tüm veriler kaybolacaktır, devam edilsin mi?'");
	
	If Partners.Count() > 0 Then
		ShowQueryBox(
			New CallbackDescription("FillInPartnerTableCompletion", ThisObject),
			QueryText, QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
	Else
		FillInTableOfPartnersOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInPartnerTableCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInTableOfPartnersOnServer();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsPartners

&AtClient
Procedure PartnersOnChange(Item)
	
	NumberOfSelectedPartners = Partners.Count();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure InitializeComposerServer(CompositionSetup)
	
	CompositionSchema = DataProcessors.SelectPartnersByFilter.GetTemplate("PartnerFilter");
	SchemaURL = PutToTempStorage(CompositionSchema,UUID);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
	
	If CompositionSetup = Undefined Then
		SettingsComposer.LoadSettings(CompositionSchema.DefaultSettings);
	Else
		SettingsComposer.LoadSettings(CompositionSetup);
		SettingsComposer.Refresh(DataCompositionSettingsRefreshMethod.CheckAvailability);
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTableOfPartnersOnServer(CheckFilling = True)
	
	Query = New Query;
	
	FilterScheme = DataProcessors.SelectPartnersByFilter.GetTemplate("PartnerFilter");
	
	TemplateComposer = New DataCompositionTemplateComposer();
	CalculationSettingsComposer = New DataCompositionSettingsComposer;
	CalculationSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(FilterScheme));
	CalculationSettingsComposer.LoadSettings(SettingsComposer.Settings);
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(CalculationSettingsComposer);
	
	DataCompositionTemplate = TemplateComposer.Execute(FilterScheme, CalculationSettingsComposer.GetSettings(),,,
		Type("DataCompositionValueCollectionTemplateGenerator"));
	
	// Initializing the layout processor
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(DataCompositionTemplate);
	
	Partners.Clear();
	TableOfPartners = FormAttributeToValue("Partners");
	
	// Getting the result
	DataCompositionResultValueCollectionOutputProcessor =
		New DataCompositionResultValueCollectionOutputProcessor;
	DataCompositionResultValueCollectionOutputProcessor.SetObject(TableOfPartners);
	DataCompositionResultValueCollectionOutputProcessor.Output(DataCompositionProcessor);
	
	If DesignedForEmails Then
		TableOfPartners.FillValues(PartnerSContactDetailsKindForEmails, "ContactDetailsKindForMails");
	EndIf;
	
	If DesignedForSMSMessage Then
		TableOfPartners.FillValues(PartnerSContactDetailsKindForSMSMessage, "CIKindPhone");
	EndIf;
	
	ValueToFormAttribute(TableOfPartners, "Partners");
	
	NumberOfSelectedPartners = Partners.Count();
	
EndProcedure

&AtServer
Function PutItInTemporaryStorageOnServer()
	
	Return PutToTempStorage(Partners.Unload(), CalledFormID);
	
EndFunction

&AtServer
Procedure ProcessPassedParameters(Var_Parameters)

	CalledFormID = Var_Parameters.UUID;
	
	If ValueIsFilled(Var_Parameters.Title) Then
		Title = Var_Parameters.Title;
	Else
		PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		                          ThisObject, "", NStr("vi = 'Chọn đối tác theo bộ lọc';
														|ru = 'Подбор контрагентов по отбору';
														|en = 'Pick counterparties by filter'; fa = 'Pick counterparties by filter';
														|it = 'Abbinamento controparti per selezione';
														|pl = 'Dobór kontrahentów dla wyboru';
														|tr = 'Filtreye göre cari hesap seçimi'"));
	EndIf;
	If ValueIsFilled(Var_Parameters.TransferButtonTitle) Then
		Commands.MoveToDocument.Title = Var_Parameters.TransferButtonTitle;
		Commands.MoveToDocument.ToolTip = Var_Parameters.TransferButtonTitle;
	EndIf;
	
	DesignedForSMSMessage                     = Var_Parameters.DesignedForSMSMessage;
	DesignedForEmails        = Var_Parameters.DesignedForEmails;
	PartnerSContactDetailsKindForSMSMessage   = Var_Parameters.PartnerSContactDetailsKindForSMSMessage;
	PartnerSContactDetailsKindForEmails = Var_Parameters.PartnerSContactDetailsKindForEmails;
	
	FillInKiSelectionLists();
	
	VisibilityManagement();

EndProcedure

&AtServer
Procedure VisibilityManagement()
	
	Items.PartnersContactDetailsKindForMails.Visible = DesignedForEmails;
	Items.PartnersCIKindPhone.Visible  = DesignedForSMSMessage;
	
EndProcedure

&AtServer
Procedure FillInKiSelectionLists()
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	ContactInformationKinds.Ref,
	|	ContactInformationKinds.Description,
	|	ContactInformationKinds.Type AS Type
	|FROM
	|	Catalog.ContactInformationKinds AS ContactInformationKinds
	|WHERE
	|	ContactInformationKinds.Parent = VALUE(Catalog.ContactInformationKinds.CatalogPartners)
	|	AND (ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Phone)
	|			OR ContactInformationKinds.Type = VALUE(Enum.ContactInformationTypes.Email))
	|TOTALS BY
	|	Type";
	
	SelectionType = Query.Execute().Select(QueryResultIteration.ByGroups);
		
		While SelectionType.Next() Do
			
			If SelectionType.Type = Enums.ContactInformationTypes.Email Then
					List = Items.PartnersContactDetailsKindForMails.ChoiceList;
				Else
					List = Items.PartnersCIKindPhone.ChoiceList;
			EndIf;
			
			DetailsSelection = SelectionType.Select();
			
			While DetailsSelection.Next() Do
				
				List.Add(DetailsSelection.Ref, DetailsSelection.Description);
				
			EndDo;
			
		EndDo;

EndProcedure

#EndRegion


#Region Initialize

ClosingInProgress = False;

#EndRegion
