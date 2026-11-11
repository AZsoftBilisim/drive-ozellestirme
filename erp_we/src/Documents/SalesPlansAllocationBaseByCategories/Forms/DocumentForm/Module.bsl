#Region Variables

&AtClient
Var IdleHandlerParameters;

&AtClient
Var TimeConsumingOperationForm;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	ParametersArray = New Array;
	ParametersArray = Common.CopyRecursive(Items.Attribute.ChoiceParameters, False);
	ParametersArray.Add(New ChoiceParameter("Filter.PropertiesSet",  PropertyManager.PropertiesSetByName("Catalog_Products")));
	Items.Attribute.ChoiceParameters = New FixedArray(ParametersArray);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	Items.StandardsByAttributesDownloadStandardsFromAFile.Enabled = Not ThisForm.ReadOnly;
	Items.StandardsByPropertiesDownloadStandardsFromAFile.Enabled = Not ThisForm.ReadOnly;
	
	// Handler of the subsystem "Versioning of objects".
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	FormEvents.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	If ThisForm.CallbackDescriptionOnClose <> Undefined
		And ValueIsFilled(Object.Ref) Then
		NewAllocationStandard = New Structure("Posted, Ref, ProductCategory, Attribute, ValidityStartDate, FillingVariant");
		FillPropertyValues(NewAllocationStandard, Object);
		ThisForm.FormOwner.NewAllocationStandard = NewAllocationStandard;
	EndIf;
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductCategoryOnChange(Item)
	If ValueIsFilled(Object.ProductCategory) Then
	
		Items.Attribute.Enabled = True;
		ProductCategoryWhenChangedOnServer();
	
	Else
	
		Items.Attribute.Enabled = False;
	
	EndIf; 
	
EndProcedure

&AtClient
Procedure AttributeChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	StandardProcessing = False;
	
	If Object.Attribute = ValueSelected 
		Or Object.Operation = PredefinedValue("Enum.TransactionsOfStandardsAllocation.StandardLock") Then
		Object.Attribute = ValueSelected;
		Return;
	EndIf;
	
	If Object.StandardsByAttributes.Count() > 0 Or Object.StandardsByProperties.Count() > 0 Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Xóa và tiếp tục';
												|ru = 'Очистить и продолжить';
												|en = 'Clear and continue'; fa = 'Clear and continue';
												|it = 'Cancellare e continuare';
												|pl = 'Oczyść i kontynuuj';
												|tr = 'Temizle ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
													|ru = 'Отмена';
													|en = 'Cancel'; fa = 'انصراف';
													|it = 'Annulla';
													|pl = 'Cancel';
													|tr = 'İptal'"));
		
		AdditionalParameters = New Structure("ValueSelected", ValueSelected);
		
		Notification = New CallbackDescription("AttributeChoiceProcessingCompletion", ThisObject, AdditionalParameters);
		ShowQueryBox(Notification, NStr("vi = 'Khi thay đổi ""Mục tin"", sẽ xóa định mức. Tiếp tục?';
										|ru = 'При изменении ""Реквизита"" нормативы будут очищены. Продолжить?';
										|en = 'Standards will be cleared while changing ""Attribute"". Continue?'; fa = 'Standards will be cleared while changing ""Attribute"". Continue?';
										|it = 'Nel caso di modifica del ""Requisito"" i normativi verranno eliminate. Continuare?';
										|pl = 'Podczas zmiany ""Реквизита"" normatywy zostaną oczyszczone. Kontynuować?';
										|tr = '""Öznitelik"" değişiminde standartlar silinecektir. Devam edilsin mi?'"), Buttons);
	
	Else
		
		AdditionalParameters = New Structure("ValueSelected", ValueSelected);
		AttributeChoiceProcessingCompletion(DialogReturnCode.Yes, AdditionalParameters);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure AttributeChoiceProcessingCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Object.Attribute = AdditionalParameters.ValueSelected;
	
	Object.StandardsByAttributes.Clear();
	Object.StandardsByProperties.Clear();
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		Object.FillingVariant = 0;
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			TypeDescription = New TypeDescription("Undefined");
			Items.StandardsByAttributesValue.TypeRestriction = TypeDescription;
			
		Else
			
			TypeDescription = New TypeDescription(AttributeStructure.AttributeType);
			Items.StandardsByAttributesValue.TypeRestriction = TypeDescription;
			
		EndIf; 
		
	Else
		
		Object.FillingVariant = 1;
		If ItemVariantsAreUsed Then
			
			Object.FillingVariant = FillingVariant(Object.ProductCategory, Object.Attribute);
			
		EndIf; 
	EndIf; 
	
	SetVisibilityByProps(ThisForm);

EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisForm, "Object.Comment");
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsStandardsByBankingDetails

&AtClient
Procedure StandardsByAttributesValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
		
			TypeDescription = New TypeDescription("Undefined");
			Items.StandardsByAttributesValue.TypeRestriction = TypeDescription;
		
		Else
		
			TypeDescription = New TypeDescription(AttributeStructure.AttributeType);
			Items.StandardsByAttributesValue.TypeRestriction = TypeDescription;
			
			If Not TypeDescription.ContainsType(TypeOf(Items.StandardsByAttributes.CurrentData.Value)) Then
			
				Items.StandardsByAttributes.CurrentData.Value = TypeDescription.AdjustValue(Undefined);
			
			EndIf;
		
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisForm);
	
EndProcedure

&AtClient
Procedure FillInAllValues(Command)
	
	If Not CheckingHeaderFilling() Then
		
		Return;
		
	EndIf;
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
		
			Return;
		
		EndIf;
	EndIf;
	
	FillInAllValuesOnServer();
	
EndProcedure

&AtClient
Procedure FillInAccordingToUsedInProducts(Command)
	
	If Not CheckingHeaderFilling() Then
		
		Return;
		
	EndIf;
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
		
			Return;
		
		EndIf;
	EndIf;
	
	FillByProductsUsedInServer();
	
EndProcedure

&AtClient
Procedure FillInAccordingToSalesStatistics(Command)
	
	If Not CheckingHeaderFilling() Then
		
		Return;
		
	EndIf;
	
	Notification = New CallbackDescription("FillInAccordingToSalesStatisticsCompletion",ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingVariant", Object.FillingVariant);
	FormParameters.Insert("Attribute", Object.Attribute);
	FormParameters.Insert("AllocationShareProcedure", Object.AllocationShareProcedure);
	
	OpenForm("Document.SalesPlansAllocationBaseByCategories.Form.FormOfPeriod",
		FormParameters,
		ThisForm,
		UUID,
		,
		,
		Notification,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure DownloadStandardsFromAFile(Command)
	
	If Not CheckingHeaderFilling() Then
		Return;
	EndIf;
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	If TypeOf(Object.Attribute) = Type("String") Then
		ImportParameters.FullTabularSectionName = "SalesPlansAllocationBaseByCategories.StandardsByAttributes";
	Else
		ImportParameters.FullTabularSectionName = "SalesPlansAllocationBaseByCategories.StandardsByProperties";
	EndIf;
	ImportParameters.Title = NStr("vi = 'Kết nhập định mức phân bổ từ tệp';
									|ru = 'Загрузка нормативов распределения из файла';
									|en = 'Import distribution standards from file'; fa = 'Import distribution standards from file';
									|it = 'Download dei normativi di ripartizione dal file';
									|pl = 'Pobieranie normatywów przydziału z pliku';
									|tr = 'Dosyadan dağıtım standartlarının yüklenmesi'");
	ImportParameters.AdditionalParameters =  New Structure;
	ImportParameters.AdditionalParameters.Insert("ProductCategory", Object.ProductCategory);
	ImportParameters.AdditionalParameters.Insert("Attribute", Object.Attribute);
	
	Notification = New CallbackDescription("DownloadStandardsFromAFileCompletion", ThisObject);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisForm);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsByAttributesValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StandardsByAttributes.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Giá trị trống>';
													|ru = '<Пустое значение>';
													|en = '<empty value>'; fa = '<empty value>';
													|it = '<Valore vuoto>';
													|pl = '<pusta wartość>';
													|tr = '<Boş değer>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardsByPropertiesValue.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.StandardsByProperties.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<Giá trị trống>';
													|ru = '<Пустое значение>';
													|en = '<empty value>'; fa = '<empty value>';
													|it = '<Valore vuoto>';
													|pl = '<pusta wartość>';
													|tr = '<Boş değer>'"));
	
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	ItemVariantsAreUsed = GetFunctionalOption("UseItemVariants");
	
	If Object.Operation = Enums.TransactionsOfStandardsAllocation.SetStandard Then
	
		Items.Pages.Visible = True;
		Items.ValidityStartDate.Visible = True;
		Items.BlockingGroup.Visible = False;
		Items.LockDate.Visible = False;
	
	Else
	
		Items.Pages.Visible = False;
		Items.ValidityStartDate.Visible = False;
		Items.BlockingGroup.Visible = True;
		Items.LockDate.Visible = True;
	
	EndIf;
	
	FillInListOfBankingDetails();
	
	PropsBeforeChanges = Object.Attribute;
	
	SetVisibilityByProps(ThisForm);

EndProcedure

&AtServer
Procedure ProductCategoryWhenChangedOnServer()
	
	FillInListOfBankingDetails();
	
EndProcedure

&AtServer
Procedure FillInListOfBankingDetails()

	AttributesStructure1 = Documents.SalesPlansAllocationBaseByCategories.GetDetailsForRegulations();
	
	Items.Attribute.ChoiceList.Clear();
	For Each KeyValue In AttributesStructure1 Do
		Items.Attribute.ChoiceList.Add(KeyValue.Key, KeyValue.Value.Presentation);
	EndDo; 
	
	ListOfAdditionalBankingDetails = Documents.SalesPlansAllocationBaseByCategories.GetAdditionalDetailsForRegulations(Object.ProductCategory);
	
	For Each ListItem In ListOfAdditionalBankingDetails Do
		Items.Attribute.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;

EndProcedure 

&AtServer
Procedure FillInAllValuesOnServer()
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		Standards = Object.StandardsByAttributes;
		
	Else
	
		Standards = Object.StandardsByProperties;
		
	EndIf; 
	
	Documents.SalesPlansAllocationBaseByCategories.FillTableOfStandardsWithAllValues(
		Standards, 
		Object.ProductCategory, 
		Object.Attribute, 
		Object.ValidityStartDate);
	
EndProcedure

&AtServer
Procedure FillByProductsUsedInServer()
	
	If TypeOf(Object.Attribute) = Type("String") Then
		
		AttributeStructure = Undefined;
		AttributesStructure1.Property(Object.Attribute, AttributeStructure);
		
		If AttributeStructure = Undefined Then
			
			Return;
			
		EndIf;
		
		Standards = Object.StandardsByAttributes;
		
	Else
	
		Standards = Object.StandardsByProperties;
		
	EndIf; 
	
	Documents.SalesPlansAllocationBaseByCategories.FillInTableOfStandardsWithValuesUsedInProductList(
		Standards, 
		Object.ProductCategory, 
		Object.Attribute, 
		Object.FillingVariant, 
		Object.ValidityStartDate);
	
EndProcedure

&AtClient
Procedure FillInAccordingToSalesStatisticsCompletion(Settings, AdditionalParameters) Export
	
	If Settings <> Undefined Then
		
		Object.AllocationShareProcedure = Settings.AllocationShareProcedure;
		
		Settings.Insert("Property",          Object.Attribute);
		Settings.Insert("Attribute",          Object.Attribute);
		Settings.Insert("ProductCategory", Object.ProductCategory);
		
		Result = FillInStatisticsOfSalesOnServer(Settings);
		
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		CallbackOnCompletion = New CallbackDescription("FillInAlertBasedOnSalesStatistics", ThisObject);
		
		TimeConsumingOperationsClient.WaitCompletion(
			Result, CallbackOnCompletion, IdleParameters);

	EndIf;
	
EndProcedure

&AtClient
Procedure FillInAlertBasedOnSalesStatistics(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		GetResultOfFillingOnServer(Result.ResultAddress);
	EndIf;
	
EndProcedure

// Parameters:
//  JobParameters - Structure - From:
//   * CustomSettingsAddress - String -
//   * Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, String -
//   * Attribute - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo, String -
//   * ProductCategory - CatalogRef.ProductCategories -
// 
// Returns:
//  See TimeConsumingOperations.ExecuteInBackground
//
&AtServer
Function FillInStatisticsOfSalesOnServer(JobParameters)
	
	JobParameters.Insert("UUID", UUID);
	JobParameters.Insert("GeneralSettingsKey",       "Document.SalesPlansAllocationBaseByCategories");
	
	Settings = New Structure;
	Settings.Insert("UserSettings",  GetFromTempStorage(JobParameters.CustomSettingsAddress));
	JobParameters.Delete("CustomSettingsAddress");
	
	Common.CommonSettingsStorageSave(JobParameters.GeneralSettingsKey, "BackgroundJobSettings_"+JobParameters.UUID, Settings);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.RunInBackground = True;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.BackgroundJobDescription =
		NStr("vi = 'Điền định mức phân bổ theo thống kê bán hàng';
			|ru = 'Заполнение нормативов распределения по статистике продаж';
			|en = 'Fill in distribution standards by sales statistics'; fa = 'Fill in distribution standards by sales statistics';
			|it = 'Compilazione dei normativi di ripartizione in base alla statistica delle vendite';
			|pl = 'Wypełnienie normatywów przydziału według statystyki sprzedaży';
			|tr = 'Satış istatistiklerine göre dağıtım standardının yüklenmesi'");
		
	Result = TimeConsumingOperations.ExecuteInBackground(
		"Documents.SalesPlansAllocationBaseByCategories.CalculateStandardsForSalesStatistics",
		JobParameters,
		ExecutionParameters);
	
	Return Result;
	
EndFunction

&AtServer
Procedure GetResultOfFillingOnServer(StorageAddress)
	
	TableOfStandards = GetFromTempStorage(StorageAddress);
	
	If Object.FillingVariant = 1 Or Object.FillingVariant = 2 Then
		Object.StandardsByProperties.Load(TableOfStandards);
	Else
		Object.StandardsByAttributes.Load(TableOfStandards);
	EndIf; 
	
EndProcedure

&AtServerNoContext
Function FillingVariant(ProductCategory, Attribute)

	Return Documents.SalesPlansAllocationBaseByCategories.FillingVariant(ProductCategory, Attribute);

EndFunction 

&AtClientAtServerNoContext
Procedure SetVisibilityByProps(Form)

	If TypeOf(Form.Object.Attribute) = Type("String") Then
		
		Form.Items.Pages.CurrentPage = Form.Items.PageStandardsByAttributes;
		
	Else
		
		Form.Items.Pages.CurrentPage = Form.Items.PageStandardsByProperties;
	
	EndIf; 
	
	If Form.Object.FillingVariant = 2 Then
	
		Title = NStr("vi = 'Sử dụng trong Đặc tính';
					|ru = 'По использованным в Характеристиках';
					|en = 'By ones used in Variants'; fa = 'By ones used in Variants';
					|it = 'In base a quelli usati nelle Caratteristiche';
					|pl = 'Według używanych w Charatkerystykach';
					|tr = 'Özelliklerin kullanımına göre'");
	
	Else
	
		Title = NStr("vi = 'Sử dụng trong Mặt hàng';
					|ru = 'По использованным в Номенклатуре';
					|en = 'By ones used in Items'; fa = 'بر اساس موارد استفاده‌شده در اقلام';
					|it = 'In base a quelli usati nell''Articolo';
					|pl = 'Wg używanych w Produktach';
					|tr = 'Ürünlerde kullanılış şekline göre'");
	
	EndIf; 
	
	Form.Items.StandardsByPropertiesFillInAccordingToUsedInProducts.Title = Title;
	
EndProcedure 

&AtClient
Function CheckingHeaderFilling()

	Result = True;
	
	If Not ValueIsFilled(Object.ValidityStartDate) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Ngày bắt đầu hiệu lực""';
				|ru = 'Поле ""Дата начала действия"" не заполнено';
				|en = '""Effective date"" is required'; fa = '""Effective date"" is required';
				|it = 'Il campo ""Data inizio di validità"" non è compilato';
				|pl = 'Nie wypełniono pola ""Data rozpoczęcia działania""';
				|tr = '""Geçerlilik başlangıç tarihi"" alanı doldurulmadı'"),
			Object.Ref,
			"ValidityStartDate",
			"Object");
		Result = False;
		
	EndIf;
	
	If Not ValueIsFilled(Object.ProductCategory) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Thể loại hàng hóa""';
				|ru = 'Поле ""Товарная категория"" не заполнено';
				|en = '""Product category"" is required'; fa = '""Product category"" is required';
				|it = 'Il campo ""Categoria merceologica"" non è compilato';
				|pl = 'Nie wypłeniono pola ""Товарная категория""';
				|tr = '""Ürün kategorisi"" alanı doldurulmadı'"),
			Object.Ref,
			"ProductCategory",
			"Object");
		Result = False;
		
	EndIf;
	
	If Not ValueIsFilled(Object.Attribute) Then
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Chưa điền trường ""Mục tin""';
				|ru = 'Поле ""Реквизит"" не заполнено';
				|en = '""Attribute"" is required'; fa = '""Attribute"" is required';
				|it = 'Il campo ""Requisito"" non è compilato';
				|pl = 'Nie wypełniono pola ""Реквизит""';
				|tr = '""Öznitelik"" alanı doldurulmadı'"),
			Object.Ref,
			"Attribute",
			"Object");
		Result = False;
		
	EndIf;
	
	Return Result;

EndFunction 

&AtClient
Procedure DownloadStandardsFromAFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	DownloadStandardsFromFileOnServer(ImportedDataAddress);
	
EndProcedure

&AtServer
Procedure DownloadStandardsFromFileOnServer(ImportedDataAddress)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesAdded = False;
	For Each TableRow In ImportedData Do 
		
		If Not ValueIsFilled(TableRow.Value) Then
			Continue;
		EndIf;
		
		If TypeOf(Object.Attribute) = Type("String") Then
			NewRow = Object.StandardsByAttributes.Add();
		Else
			NewRow = Object.StandardsByProperties.Add();
		EndIf;
		NewRow.Value = TableRow.Value;
		NewRow.AllocationPercentage = TableRow.AllocationPercentage;
		LinesAdded = True;
		
	EndDo;
	
	If LinesAdded Then
		Modified = True;
	EndIf;
	
EndProcedure

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
