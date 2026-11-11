#Region Variables

&AtClient
Var CachedValues;

&AtClient
Var CurDataId; //used to pass the current line to the wait handler

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	TMCommonUse.CustomizePeripherals(ThisObject);
	
	Items.IssueQualityControlReport.Enabled = AccessRight("Insert",
		Metadata.Documents.GoodsQualityControlCertificate);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If ValueIsFilled(Object.RequestForControl) Then
		Items.Basis.Title = Common.SubjectString(Object.RequestForControl);
	EndIf;
	
	ItemsAvailability = AccessRight("Insert", Metadata.Documents.GoodsQualityResearch);
	
	// Handler of the "Destination" mechanism
	Catalogs.Assignments.DocumentFormWhenCreatedOnServer(ThisObject, "Object.PlanAndResearchResult.Purpose");
	
	// Working With The Clipboard
	SetAvailabilityOfClipboardCommands();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	InitializeCache();
	
	ConfigureDependentFormElements(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties 
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyAboutDocument(WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// The end of the standard subsystem.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods_Research, StructureOfActions);
	
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.PlanAndResearchResult, StructureOfActions);
	
	UpdateResearchResult();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties

	DocumentObject = FormAttributeToValue("Object");
	DocumentObject.AdditionalProperties.Insert("OneItemOfProducts", Not ExploreMultipleGoods);

	If Not DocumentObject.CheckFilling() Then
		Cancel = True;
	EndIf;
		
	CheckedAttributes.Clear();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Document.GoodsQualityResearch.Form.FormForPickingGoodsFromRequestForQualityControl" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		ConfigureDependentFormElements(ThisObject, "FormType");
		
	ElsIf ProductsClient.ThisIsIndicationOfSeries(ChoiceSource) Then
		
		ProductsClient.ProcessSeriesIndication(
			ThisObject, SeriesSpecificationParameters[ValueSelected.TSName], ValueSelected);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If IsInputAvailable() And Source = "Peripherals" Then
		If EventName = "ScanData"
			And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToArray(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	// Unknown barcodes
	If EventName = "UnknownBarcodes"
		And Source = "Peripherals"
		And Parameter.OwnerForm = UUID Then
		
		CachedValues.Barcodes.Clear();
		BarcodeData_5 = New Array;
		For Each ReceivedBarcode In Parameter.ItemsBarcodes Do
			BarcodeData_5.Add(ReceivedBarcode);
		EndDo;
		
		ProcessBarcodes(BarcodeData_5);
		
	EndIf;
	
 	// Working With The Clipboard
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommandsOnClient();
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BasisClick(Item)
	
	If ValueIsFilled(Object.RequestForControl) Then
		FormParameters = New Structure("Key", Object.RequestForControl);
		OpenForm("Document.RequestForGoodsQualityControl.ObjectForm", FormParameters);
	Else
		OpenForm("Document.RequestForGoodsQualityControl.ChoiceForm", , ThisObject, , , ,
			New CallbackDescription("FillOutApplicationForQualityControlOfItemsEnd", ThisObject));
	EndIf;
	
EndProcedure

&AtClient
Procedure TypeOfControlOnChange(Item)
	
	If TypeOfControlBeforeChange = Object.Control Then
		Return;
	EndIf;
	
	If Object.Control = PredefinedValue("Enum.QualityControl.Selective")
		And Object.InstancesCheckMethod <> PredefinedValue(
		"Enum.CheckOptionsOfResearchCopies.CopyByCopy") Then
		
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continue';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Khi thay đổi loại kiểm soát, các kiểm nghiệm đã nhập sẽ bị xóa.';
						|ru = 'При изменении вида контроля введенные исследования будут очищены.';
						|en = 'When you change the control kind, the entered research will be cleared.'; fa = 'When you change the control kind, the entered research will be cleared.';
						|it = 'When you change the control kind, the entered research will be cleared.';
						|pl = 'When you change the control kind, the entered research will be cleared.';
						|tr = 'Kontrol türü değiştirildiğinde girilen incelemeler temizlenecek.'");

		CallbackDescription = New CallbackDescription("TypeOfControlOnChangeCompletion", ThisObject);
		
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
		
	EndIf;
	
	TypeOfControlBeforeChange = Object.Control;
	
	ConfigureDependentFormElements(ThisObject, "Control");

EndProcedure

&AtClient
Procedure HowToCheckInstancesOnChange(Item)
	
	If ResearchMethodBeforeChange = Object.InstancesCheckMethod Then
		Return;
	EndIf;

	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục?';
											|ru = 'Продолжить?';
											|en = 'Continue?'; fa = 'Continue?';
											|it = 'Continue?';
											|pl = 'Continue?';
											|tr = 'Devam edilsin mi?'"));
	Buttons.Add(DialogReturnCode.Cancel);

	QueryText = NStr("vi = 'Khi thay đổi phương thức kiểm tra mẫu, các kiểm nghiệm đã nhập sẽ bị xóa.';
					|ru = 'При изменении способа проверки образцов введенные исследования будут очищены.';
					|en = 'When you change the method to check samples, the entered research will be cleared.'; fa = 'When you change the method to check samples, the entered research will be cleared.';
					|it = 'When you change the method to check samples, the entered research will be cleared.';
					|pl = 'When you change the method to check samples, the entered research will be cleared.';
					|tr = 'Örneklerin kontrol yöntemi değiştirildiğinde girilen incelemeler temizlenecektir.'");

	CallbackDescription = New CallbackDescription("HowToCheckInstancesOnChangeCompletion", ThisObject);

	ShowQueryBox(CallbackDescription, QueryText, Buttons);
	
EndProcedure

&AtClient
Procedure GoodsResearchSheetOnChange(Item)
	
	If MapOfStudyBeforeChange = Object.GoodsResearchSheet Then
		Return;
	EndIf;
	
	If ValueIsFilled(MapOfStudyBeforeChange) Then
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
												|ru = 'Продолжить';
												|en = 'Continue'; fa = 'ادامه';
												|it = 'Continue';
												|pl = 'Continue';
												|tr = 'Devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Khi thay đổi sơ đồ kiểm nghiệm hàng hóa, các kiểm nghiệm đã nhập sẽ bị xóa.';
						|ru = 'При изменении карты исследования товаров введенные исследования будут очищены.';
						|en = 'When you change the goods research sheet, the entered research will be cleared.'; fa = 'When you change the goods research sheet, the entered research will be cleared.';
						|it = 'When you change the goods research sheet, the entered research will be cleared.';
						|pl = 'When you change the goods research sheet, the entered research will be cleared.';
						|tr = 'Ürün inceleme kartı değiştirildiğinde girilen incelemeler temizlenecek.'");

		CallbackDescription = New CallbackDescription("GoodsResearchSheetOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);
	Else
		MapOfStudyBeforeChange = Object.GoodsResearchSheet;
		FillInServiceDetailsONChangingStudyCard();
		ConfigureDependentFormElements(ThisObject, "GoodsResearchSheet");
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure CompletedOnChange(Item)
	
	ClearMessages();
	Cancel = False;
	Errors = New Array;

	If Object.DeletionMark Then
		MessageText = NStr("vi = 'Không thể thay đổi trạng thái của kiểm nghiệm hàng hóa đã được đánh dấu xóa.';
							|ru = 'Нельзя изменить статус помеченного на удаление исследования товаров.';
							|en = 'Cannot change the status of goods research marked for deletion.'; fa = 'Cannot change the status of goods research marked for deletion.';
							|it = 'Cannot change the status of goods research marked for deletion.';
							|pl = 'Cannot change the status of goods research marked for deletion.';
							|tr = 'Silinmek üzere işaretlenmiş ürün incelemesinin durumu değiştirilemez.'");
		ErrorStructure = New Structure;
		ErrorStructure.Insert("MessageText", MessageText);
		ErrorStructure.Insert("Field","");
		Errors.Add(ErrorStructure);
		Cancel = True;
	EndIf;
	
	If Not ValueIsFilled(Object.RequestForControl) Then
		MessageText = NStr("vi = 'Chưa điền ""Giấy đề nghị kiểm soát chất lượng"".';
							|ru = 'Не заполнена ""Заявка на контроль качества"".';
							|en = 'The ""Request for quality control"" is not filled in.'; fa = 'The ""Request for quality control"" is not filled in.';
							|it = 'The ""Request for quality control"" is not filled in.';
							|pl = 'The ""Request for quality control"" is not filled in.';
							|tr = '""Kalite Kontrol Talebi"" doldurulmamış.'");
		ErrorStructure = New Structure;
		ErrorStructure.Insert("MessageText", MessageText);
		ErrorStructure.Insert("Field","");
		Errors.Add(ErrorStructure);
		Cancel = True;
	EndIf;
	
	If Not ValueIsFilled(Object.GoodsResearchSheet) Then
		MessageText = NStr("vi = 'Chưa điền ""Sơ đồ kiểm nghiệm hàng hóa"".';
							|ru = 'Не заполнена ""Карта исследования товаров"".';
							|en = 'The ""Goods research sheet"" is not filled in.'; fa = 'The ""Goods research sheet"" is not filled in.';
							|it = 'The ""Goods research sheet"" is not filled in.';
							|pl = 'The ""Goods research sheet"" is not filled in.';
							|tr = '""Ürün İnceleme Kartı"" doldurulmamış.'");
		ErrorStructure = New Structure;
		ErrorStructure.Insert("MessageText", MessageText);
		ErrorStructure.Insert("Field","Object.GoodsResearchSheet");
		Errors.Add(ErrorStructure);
		Cancel = True;
	EndIf;
	
	If Object.PlanAndResearchResult.Count() = 0 Then
		If ExploreMultipleGoods Then
			MessageText = NStr("vi = 'Chưa điền ""Kế hoạch và kết quả kiểm nghiệm"".';
								|ru = 'Не заполнен ""План и результат исследования"".';
								|en = 'The ""Plan and research result"" is not filled in.'; fa = 'The ""Plan and research result"" is not filled in.';
								|it = 'The ""Plan and research result"" is not filled in.';
								|pl = 'The ""Plan and research result"" is not filled in.';
								|tr = '""İnceleme Planı ve Sonucu"" doldurulmamış.'");
			ErrorStructure = New Structure;
			ErrorStructure.Insert("MessageText", MessageText);
			ErrorStructure.Insert("Field","Object.PlanAndResearchResult");
		Else
			MessageText = NStr("vi = 'Chưa điền ""Kế hoạch kiểm nghiệm"".';
								|ru = 'Не заполнен ""План исследования"".';
								|en = 'The ""Research plan"" is not filled in.'; fa = 'The ""Research plan"" is not filled in.';
								|it = 'The ""Research plan"" is not filled in.';
								|pl = 'The ""Research plan"" is not filled in.';
								|tr = '""İnceleme Planı"" doldurulmamış.'");
			ErrorStructure = New Structure;
			ErrorStructure.Insert("MessageText", MessageText);
			ErrorStructure.Insert("Field","Object.PlanAndResearchResult");
		EndIf;
		Errors.Add(ErrorStructure);
		Cancel = True;
	EndIf;
	
	If Not Cancel Then
		Errors = CheckImplementationOfResearchPlan(Cancel);
	EndIf;
	
	If Cancel Then
		For Each Message In Errors Do
			If ValueIsFilled(Message.Field) Then
				CommonClient.MessageToUser(Message.MessageText,,Message.Field,,Cancel);
			Else
				CommonClient.MessageToUser(Message.MessageText,,,,Cancel);
			EndIf;
		EndDo;
		Object.Completed = False;
		Return;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Status");
	
EndProcedure

&AtClient
Procedure DecorationAddInstanceClick(Item)
	
	SampleTemplate = NStr("vi = 'Mẫu số: %1';
							|ru = 'Образец №:%1';
							|en = 'Template No.%1'; fa = 'Template No.%1';
							|it = 'Template No.%1';
							|pl = 'Template No.%1';
							|tr = 'Numune No: %1'");
	
	If Not ExploreMultipleGoods Then
		CurrentData = Items.PlanAndResearchResult.CurrentData;
	Else
		If ItemOfSample = "AllProducts" Then
			CurrentData = Items.PlanAndResearchResult.CurrentData;
		Else
			Filter = New Structure;
			Filter.Insert("RowID", ItemOfSample);
			FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundRows.Count() > 0 Then
				CurrentData = FoundRows[0];
			EndIf;
		EndIf;
	EndIf;
	
	ItemVariantsAreUsed = True;
	If CurrentData <> Undefined Then
		LastAddedItem = CurrentData.Products;
		LastAddedCharacteristic = CurrentData.Characteristic;
		LastAddedBatch = CurrentData.Series;
		ItemVariantsAreUsed = CurrentData.ItemVariantsAreUsed;
	EndIf;
	
	TamplatesNumber = 1;
	
	ArrayOfDifferentSamples = New Array();
	For Each ResearchString In Object.Goods_Research Do
		ArrayOfDifferentSamples.Add(ResearchString.InstanceId);
	EndDo;
	ArrayOfDifferentSamples = CommonClientServer.CollapseArray(ArrayOfDifferentSamples);
	TamplatesNumber = ArrayOfDifferentSamples.Count()+1;
	
	CurrentSampleNumber =  StringFunctionsClientServer.SubstituteParametersToString(SampleTemplate, TamplatesNumber);
	
	FormParameters = New Structure;
		
	FormParameters.Insert("Products", LastAddedItem);
	FormParameters.Insert("Characteristic", LastAddedCharacteristic);
	FormParameters.Insert("Pattern", CurrentSampleNumber);
	FormParameters.Insert("ItemVariantsAreUsed", ItemVariantsAreUsed);
	FormParameters.Insert("ProductSelectionList", ItemUsedIsPlanAndResultOfStudy());
	FormParameters.Insert("CharacteristicSelectionList", CharacteristicsOfItemUsedArePlanAndResultOfStudy());
	
	CallbackDescription = New CallbackDescription(
		"OpenAddSampleEndForm",
		ThisObject);
	
	OpenForm("Document.GoodsQualityResearch.Form.TemplateAdditionForm", FormParameters, ThisObject,,,, CallbackDescription);
			
EndProcedure

&AtClient
Procedure DecorationSelectInstanceByClicking(Item)

	Patterns = GoodsResearchSamples();
	
	FormParameters = New Structure;
		
	FormParameters.Insert("Patterns", Patterns);
	
	CallbackDescription = New CallbackDescription(
		"OpenSampleSelectionEndForm",
		ThisObject);
	
	OpenForm("Document.GoodsQualityResearch.Form.FormTemplateSelection", FormParameters, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure DecorationAllInstancesArePressed(Item)
	
	ShowAllInstances = True;
	
	If Not ExploreMultipleGoods Then
		Items.Goods_Research.RowFilter = Undefined;
		Items.Goods_Research.Refresh();
	Else
		If ItemOfSample = "AllProducts" Then
			Items.Goods_Research.RowFilter = Undefined;
			Items.Goods_Research.Refresh();
		Else
			Filter = New Structure;
			Filter.Insert("RowID", ItemOfSample);
			FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundRows.Count() > 0 Then

				Filter = New Structure;
				Filter.Insert("Products", FoundRows[0].Products);
				Filter.Insert("Characteristic", FoundRows[0].Characteristic);
				If ValueIsFilled(FoundRows[0].Series) Then
					Filter.Insert("Series", FoundRows[0].Series);
				EndIf;
				Items.Goods_Research.RowFilter = New FixedStructure(Filter);
				Items.Goods_Research.Refresh();
			EndIf;
		EndIf;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtClient
Procedure PlanAndResultOfStudyItem1OnChange(Item)
	
	TableRow = Items.PlanAndResearchResult.CurrentData;
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	CheckSeriesCalculateStatus = New Structure("Warehouse,SeriesSpecificationParameters",
		Object.Warehouse, SeriesSpecificationParameters["PlanAndResearchResult"]);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "PlanAndResearchResult");
		
	FillInArticleAttribute = New Structure("Products", "SKU");

	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	StructureOfActions.Insert("CheckFillPackageByOwner", TableRow.Package);
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
	UpdateInformationOnUseOfBatchCharacteristics();
	
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)

	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdditionalPage"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
		
	EndIf;
	// End StandardSubsystems.Properties
	
	If CurrentPage.Name = "TestReportPage" Then

		ConfigureDependentFormElements(ThisObject, "ItemOfSample");
		If ExploreMultipleGoods Then
			Items.ItemOfSample.ChoiceList.Clear();
			ItemList = ItemUsedCharacteristicsBatchPlanAndResultOfStudy();
			
			Items.ItemOfSample.ChoiceList.Add("AllProducts", NStr("vi = 'Tất cả các mặt hàng';
																	|ru = 'Вся номенклатура';
																	|en = 'All products'; fa = 'همه محصولات';
																	|it = 'All products';
																	|pl = 'All products';
																	|tr = 'Tüm öğeler'"));
			For Each ArrayElement In ItemList Do
				Items.ItemOfSample.ChoiceList.Add(ArrayElement.RowID,
					ProductsClientServer.ProductPresentation(ArrayElement.Products,
					ArrayElement.Characteristic, , ArrayElement.Series, ));
			EndDo;
			
			If Not ValueIsFilled(ItemOfSample) Then
				ItemOfSample = "AllProducts";
			EndIf;
			
			RefreshDataRepresentation(Items.ItemOfSample);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultPackageOnChange(Item)
	
	TableRow = Items.PlanAndResearchResult.CurrentData;
	StructureOfActions = New Structure();
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure BatchesIndicationStatusClick(Item, StandardProcessing)
	
	OpenSelectionOfSeries();
	
EndProcedure

&AtClient
Procedure PlanAndResultOfStudyBatch1OnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.PlanAndResearchResult.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.PlanAndResearchResult.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters["PlanAndResearchResult"], ValueSelected);

EndProcedure

&AtClient
Procedure PlanAndResultOfStudyBatch1StartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure ItemOfSampleOnChange(Item)
	
	If ItemOfSample = "AllProducts" Then
		Items.Goods_Research.RowFilter = Undefined;
		Items.Goods_Research.Refresh();
	Else
		Filter = New Structure;
		Filter.Insert("RowID", ItemOfSample);
		FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
		If FoundRows.Count() > 0 Then
			Filter = New Structure;
			Filter.Insert("Products", FoundRows[0].Products);
			Filter.Insert("Characteristic", FoundRows[0].Characteristic);
			If ValueIsFilled(FoundRows[0].Series) Then
				Filter.Insert("Series", FoundRows[0].Series);
			EndIf;
			Items.Goods_Research.RowFilter = New FixedStructure(Filter);
			Items.Goods_Research.Refresh();
		EndIf;
	EndIf;
	
	ShowAllInstances = True;
	ConfigureDependentFormElements(ThisObject, "Filter");

EndProcedure

&AtClient
Procedure OneItemONChange(Item)
	UpdateInformationOnUseOfBatchCharacteristics();
	ConfigureDependentFormElements(ThisObject, "FormType");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPlanAndResearchResult

&AtClient
Procedure PlanAndResearchResultProductsOnChange(Item)
	
	TableRow = Items.PlanAndResearchResult.CurrentData;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	CheckSeriesCalculateStatus = New Structure("Warehouse,SeriesSpecificationParameters",
		Object.Warehouse, SeriesSpecificationParameters["PlanAndResearchResult"]);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "PlanAndResearchResult");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	StructureOfActions.Insert("CheckFillPackageByOwner", TableRow.Package);
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.PlanAndResearchResult.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.PlanAndResearchResult.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters["PlanAndResearchResult"], ValueSelected);
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultSeriesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	OpenSelectionOfSeries(Item.EditText);
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultOnActivateRow(Item)
	
	FormEventsClient.OnActivateRow(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultBeforeDeleteRow(Item, Cancel)
	
	If Item.Name = "PlanAndResearchResult" Then
		
		DisplayWarning_ = False;
		For Each CurID_ In Item.SelectedRows Do
			TableRow = Object.PlanAndResearchResult.FindByID(CurID_);
			If TableRow = Undefined Then
				Continue;
			EndIf;
	
			Filter = New Structure;
			Filter.Insert("Products", TableRow.Products);
			Filter.Insert("Characteristic", TableRow.Characteristic);
			Filter.Insert("Series", TableRow.Series);
			FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundRows.Count() = 1 Then
				DisplayWarning_ = True;
				Break;
			EndIf;
		EndDo;

		If DisplayWarning_ Then
			Cancel = True;
		
			Buttons = New ValueList;
			Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continue';
													|pl = 'Continue';
													|tr = 'Devam et'"));
			Buttons.Add(DialogReturnCode.Cancel);

			QueryText = NStr("vi = 'Khi xóa hàng hóa, các nghiên cứu đã nhập cho hàng hóa đó sẽ bị xóa.';
							|ru = 'При удалении товара введенные для него исследования будут очищены.';
							|en = 'When you delete the goods, the research you entered for it will be cleared.'; fa = 'When you delete the goods, the research you entered for it will be cleared.';
							|it = 'When you delete the goods, the research you entered for it will be cleared.';
							|pl = 'When you delete the goods, the research you entered for it will be cleared.';
							|tr = 'Ürün silindiğinde onun için girilen incelemeler temizlenecek.'");

			CallbackDescription = New CallbackDescription("PlanAndResearchResultBeforeDeleteRowCompletion", ThisObject);
			
			ShowQueryBox(CallbackDescription, QueryText, Buttons);
		Else
			ConfigureDependentFormElements(ThisObject, "FormType");
			PlanAndResultOfStudyBeforeDeletionAtServer();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultQuantityAppropriateOnChange(Item)
	UpdateResearchResult();
EndProcedure

&AtClient
Procedure PlanAndResearchResultQuantityRejectableOnChange(Item)
	UpdateResearchResult();
EndProcedure

&AtClient
Procedure PlanAndResearchResultQuantityDamagedOnChange(Item)
	UpdateResearchResult();
EndProcedure

&AtClient
Procedure PlanAndResearchResultOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Or Copy Then
		Item.CurrentData.RowID = New UUID;
	EndIf;
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultOnChange(Item)
	ConfigureDependentFormElements(ThisObject, "FormType");
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersGoods_Research

&AtClient
Procedure Goods_ResearchSeriesOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	
	ValueSelected.Value = Items.Goods_Research.CurrentData.Series;
	ValueSelected.CurrentRowID = Items.Goods_Research.CurrentData.GetID();
	
	ProductsClient.ProcessSeriesIndication(ThisObject, SeriesSpecificationParameters["Goods_Research"], ValueSelected);
	
EndProcedure

&AtClient
Procedure Goods_ResearchSeriesStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	PickUpBatchesOnClient(Item.EditText);
	
EndProcedure

&AtClient
Procedure Goods_ResearchOnChange(Item)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Not ExploreMultipleGoods Then
		
		Filter = New Structure;
		Filter.Insert("Products", CurrentData.Products);
		Filter.Insert("Characteristic", CurrentData.Characteristic);

		Result = StudyIsCompleted(Filter);

		FoundObjectsOfResearch = Object.PlanAndResearchResult.FindRows(Filter);
		For Each Item In FoundObjectsOfResearch Do
			Item.Result = Result;
		EndDo;

		FillInResearchResult();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure Goods_ResearchRealOnChange(Item)

	SetResultOfStudyForLine();

EndProcedure 

&AtClient
Procedure Goods_ResearchNormOnChange(Item)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If ValueIsFilled(CurrentData.Real) Then
		SetResultOfStudyForLine();
	EndIf;
	
EndProcedure

&AtClient
Procedure Goods_ResearchCheckKindOnChange(Item)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	QualityIndicatorFillInSelectionList(ThisObject, CurrentData.CheckKind);
	
EndProcedure

&AtClient
Procedure Goods_ResearchOnActivateRow(Item)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	QualityIndicatorFillInSelectionList(ThisObject, CurrentData.CheckKind);
	
EndProcedure

&AtClient
Procedure Goods_ResearchCheckKindStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentRow = Items.Goods_Research.CurrentData;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentRow", CurrentRow);
	
	ClosingNotification = New CallbackDescription("ProcessResultOfTypeOfCheckSelection", ThisObject, AdditionalParameters);
	
	OpenForm("Catalog.GoodsResearchSheets.Form.ChoiceFormOfCheckKind",
		, Item,,,, ClosingNotification, FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

// Parameters:
// ValueSelected - CatalogRef.ProductCrossReferences
// AdditionalParameters - Structure
// 
&AtClient
Procedure ProcessResultOfTypeOfCheckSelection(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	
	If ValueSelected <> AdditionalParameters.CurrentRow.CheckKind Then
		AdditionalParameters.CurrentRow.QualityIndicator = "";
	EndIf;
	
	AdditionalParameters.CurrentRow.CheckKind = ValueSelected;

EndProcedure

&AtClient
Procedure Goods_ResearchProductsOnChange(Item)
	
	TableRow = Items.Goods_Research.CurrentData;
	
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse,SeriesSpecificationParameters",
		Object.Warehouse, SeriesSpecificationParameters["Goods_Research"]);
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods_Research");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	BatchProcessingOfTablePartClient.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure Goods_ResearchCountOnChange(Item)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	FoundRows = Object.Goods_Research.FindRows(New Structure("InstanceId", CurrentData.InstanceId));
	For Each TSRow In FoundRows Do
		TSRow.Count = CurrentData.Count;
	EndDo;
	
EndProcedure

&AtClient
Procedure Goods_ResearchProductsStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	Item.ChoiceList.Clear();
	ItemList = ItemUsedIsPlanAndResultOfStudy();
	For Each ArrayElement In ItemList Do
		Item.ChoiceList.Add(ArrayElement, String(ArrayElement));
	EndDo;

EndProcedure

&AtClient
Procedure Goods_ResearchCharacteristicStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Item.ChoiceList.Clear();
	ListOfCharacteristics = CharacteristicsUsedArePlanAndResultOfStudy(CurrentData.Products);
	For Each ArrayElement In ListOfCharacteristics Do
		Item.ChoiceList.Add(ArrayElement, String(ArrayElement));
	EndDo;

EndProcedure

&AtClient
Procedure Goods_ResearchOnStartEdit(Item, NewRow, Copy)

	If NewRow And Not Copy Then
		If ShowAllInstances Then
			If Not ExploreMultipleGoods Then
				CurrentData = Items.PlanAndResearchResult.CurrentData;
			Else
				If ItemOfSample = "AllProducts" Then
					CurrentData = Items.PlanAndResearchResult.CurrentData;
				Else
					Filter = New Structure;
					Filter.Insert("RowID", ItemOfSample);
					FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
					If FoundRows.Count() > 0 Then
						CurrentData = FoundRows[0];
					EndIf;
				EndIf;
			EndIf;

			If CurrentData <> Undefined Then

				TableRow = Item.CurrentData;

				TableRow.Products = CurrentData.Products;
				TableRow.Characteristic = CurrentData.Characteristic;
				TableRow.Series = CurrentData.Series;

				IdOfRowBeingEdited = TableRow.GetID();

				FillInIdOfItemResearchLineATServer(
					IdOfRowBeingEdited);

				FillInServiceAttributesWhenAddingGoodsResearchLineATServer(
					IdOfRowBeingEdited);

			EndIf;
		Else
			Filter = Items.Goods_Research.RowFilter;
			InstanceId = Undefined;
			If Filter.Property("InstanceId") And ValueIsFilled(Filter.InstanceId) Then
				InstanceId = Filter.InstanceId[0];
			Else
				Return;
			EndIf;

			FoundRows = Object.Goods_Research.FindRows(New Structure("InstanceId",
				InstanceId));
			If FoundRows.Count() = 0 Then
				Return;
			EndIf;

			TableRow = Item.CurrentData;
			TableRow.Products = FoundRows[0].Products;
			TableRow.Characteristic = FoundRows[0].Characteristic;
			TableRow.Series = FoundRows[0].Series;
			TableRow.Pattern = FoundRows[0].Pattern;

			IdOfRowBeingEdited = TableRow.GetID();

			FillInIdOfItemResearchLineATServer(
					IdOfRowBeingEdited);

			FillInServiceAttributesWhenAddingGoodsResearchLineATServer(
					IdOfRowBeingEdited);

		EndIf;

	EndIf;

EndProcedure

&AtClient
Procedure GoodsResearchInstanceEndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	TableRow = Items.Goods_Research.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;

	IdOfRowBeingEdited = TableRow.GetID();
			
	FillInIdOfItemResearchLineATServer(IdOfRowBeingEdited, Text);
	
EndProcedure

&AtClient
Procedure GoodsInstanceResearchONChange(Item)
	
	If ShowAllInstances Then
		Return;
	EndIf;
	
	TableRow = Items.Goods_Research.CurrentData;
	If TableRow = Undefined Then
		Return;
	EndIf;
	
	ItemResearchEstablishSelectionByInstance(TableRow.Pattern);
	
EndProcedure

&AtClient
Procedure Goods_ResearchDamagedOnChange(Item)
	If Object.Control = PredefinedValue("Enum.QualityControl.Solid") Then
		TableRow = Items.Goods_Research.CurrentData;
		If TableRow = Undefined Then
			Return;
		EndIf;
		If TableRow.Damaged Then
			TableRow.Result = PredefinedValue("Enum.GoodsResearchResult.NotPassed");
		EndIf;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region AttachableCommands

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.PlanAndResearchResult) Then
		SelectedRows = Items.PlanAndResearchResult.SelectedRows;
		CopyLinesOnServer(SelectedRows, "PlanAndResearchResult");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	ClearMessages();
	NumberOfProductsBeforeInsertion = Object.PlanAndResearchResult.Count();
	
	GetLinesFromClipboard();
	
	NumberOfInserted = Object.PlanAndResearchResult.Count() - NumberOfProductsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	ConfigureDependentFormElements(ThisObject, "FormType");

EndProcedure

&AtClient
Procedure CopyGoodsResearchLines(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.Goods_Research) Then
		SelectedRows = Items.Goods_Research.SelectedRows;
		CopyLinesOnServer(SelectedRows, "Goods_Research");
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure InsertGoodsResearchLines(Command)
	
	ClearMessages();
	QuantityBeforeInsertion = Object.Goods_Research.Count();
	
	GetLinesFromResearchClipboard();
	
	NumberOfInserted = Object.Goods_Research.Count() - QuantityBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);

EndProcedure

&AtClient
Procedure SplitRow(Command)
	
	FormTable  = Items.PlanAndResearchResult;
	TableData = Object.PlanAndResearchResult;
	
	Notification = New CallbackDescription("SplitRowCompletion", ThisObject);
	ProcessingOfTabularFormsClient.SplitRow(TableData, FormTable, Notification);
	
EndProcedure

&AtClient
Procedure SearchByBarcode(Command)
	
	ClearMessages();
	Notification = New CallbackDescription("ResearchPlanAndResultBarcodeSearchEnd", ThisObject);
	BarcodingOfItemsClient.ShowBarcodeInput(Notification);
	
EndProcedure

&AtClient
Procedure SelectGoods(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.RequestForControl) Then
		MessageText = NStr("vi = 'Lệnh không thể thực hiện vì chưa điền ""Giấy đề nghị kiểm soát chất lượng"".';
							|ru = 'Команда не может быть выполнена, не заполнена ""Заявка на контроль качества"".';
							|en = 'Cannot run the command. The ""Request for quality control"" is not filled in.'; fa = 'Cannot run the command. The ""Request for quality control"" is not filled in.';
							|it = 'Cannot run the command. The ""Request for quality control"" is not filled in.';
							|pl = 'Cannot run the command. The ""Request for quality control"" is not filled in.';
							|tr = 'Komut gerçekleştirilemez, ""Kalite Kontrol Talebi"" doldurulmamış.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("Warehouse", Object.Warehouse);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("Document", Object.Ref);
	FormParameters.Insert("RequestForControl", Object.RequestForControl);

	OpenForm("Document.GoodsQualityResearch.Form.FormForPickingGoodsFromRequestForQualityControl",
		FormParameters,
		ThisObject,,,, Undefined, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure PickUpChecks(Command)
	
	If Checks.Count() = 0 Then
		MessageTemplate = NStr("vi = 'Các kiểm tra chưa được thiết lập cho sơ đồ nghiên cứu ""%1""';
								|ru = 'Для карты исследования ""%1"" проверки не заданы';
								|en = 'No checks are set for the ""%1"" research sheet'; fa = 'No checks are set for the ""%1"" research sheet';
								|it = 'No checks are set for the ""%1"" research sheet';
								|pl = 'No checks are set for the ""%1"" research sheet';
								|tr = '""%1"" inceleme kartı için kontroller tanımlanmamış'");
		MessageText = StrTemplate(MessageTemplate, Object.GoodsResearchSheet);
		ShowMessageBox(, MessageText);
		Return;
	EndIf;
		
	PickUpChecksAtServer();
	
EndProcedure

&AtClient
Procedure FillInResult(Command)

	If Items.Goods_Research.SelectedRows.Count() = 0 Then
		ShowMessageBox( , NStr("vi = 'Cần phải chọn các dòng có nghiên cứu';
								|ru = 'Необходимо выбрать строки с исследованием';
								|en = 'Select lines with research'; fa = 'Select lines with research';
								|it = 'Select lines with research';
								|pl = 'Select lines with research';
								|tr = 'İnceleme içeren satırların seçilmesi gerekir'"));
		Return;
	EndIf;

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("RowID", Items.Goods_Research.SelectedRows);
	
	ChoiceData = New ValueList();
	
	If Object.InstancesCheckMethod <> PredefinedValue("Enum.CheckOptionsOfResearchCopies.WithVariances") Then
		ChoiceData.Add(PredefinedValue("Enum.GoodsResearchResult.IsPassed"));
	EndIf;
	ChoiceData.Add(PredefinedValue("Enum.GoodsResearchResult.NotPassed"));
	ChoiceData.Add(PredefinedValue("Enum.GoodsResearchResult.PassedWithOtherQuality"));
	
	SelectionParameters_1 = New Structure;
	SelectionParameters_1.Insert("Ref", ChoiceData);
	
	FormParameters = New Structure;
	FormParameters.Insert("InstancesCheckMethod", Object.InstancesCheckMethod);
	FormParameters.Insert("Filter", SelectionParameters_1);
	CallbackDescription = New CallbackDescription("SetResultToEnd", ThisObject, AdditionalParameters);
	OpenForm("Enum.GoodsResearchResult.ChoiceForm", FormParameters, ThisObject, , , , CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure FillInTotal(Command)
	
	If Object.Goods_Research.Count() = 0 Then
		ShowMessageBox(, NStr("vi = 'Các nghiên cứu chưa được thực hiện, cần phải điền các nghiên cứu';
								|ru = 'Исследования не выполнялись, необходимо заполнить исследования';
								|en = 'The research was not performed. Fill in the research'; fa = 'The research was not performed. Fill in the research';
								|it = 'The research was not performed. Fill in the research';
								|pl = 'The research was not performed. Fill in the research';
								|tr = 'İncelemeler yapılmamış, incelemelerin doldurulması gerekir'"));
		Return;
	EndIf;

	FillInResearchResult();
	
EndProcedure

&AtClient
Procedure IssueQualityControlReport(Command)
	
	ClearMessages();
	
	If Not Object.Posted Or Modified Then

		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tiếp tục';
												|ru = 'Провести и продолжить';
												|en = 'Post and continue'; fa = 'Post and continue';
												|it = 'Pubblicare e continuare';
												|pl = 'Zatwierdzić i kontynuować';
												|tr = 'Kaydet ve devam et'"));
		Buttons.Add(DialogReturnCode.Cancel);

		QueryText = NStr("vi = 'Để lập chứng từ kiểm soát chất lượng, cần phải kết chuyển chứng từ.';
						|ru = 'Для оформления акта контроля качества необходимо провести документ.';
						|en = 'To issue a quality control certificate, post the document.'; fa = 'To issue a quality control certificate, post the document.';
						|it = 'To issue a quality control certificate, post the document.';
						|pl = 'To issue a quality control certificate, post the document.';
						|tr = 'Kalite Kontrol Tutanağı düzenlemek için belgenin kaydedilmesi gerekir.'");

		CallbackDescription = New CallbackDescription("IssueQualityControlReportCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, Buttons);

	Else

		OpenQualityControlReport();

	EndIf;

EndProcedure

&AtClient
Procedure PickUpBatches(Command)
	
	PickUpBatchesOnClient();
	
EndProcedure

&AtClient
Procedure SpecifySeries(Command)
	
	OpenSelectionOfSeries();
	
EndProcedure

#EndRegion

#Region Private

#Region CheckKind

&AtClientAtServerNoContext
Procedure QualityIndicatorFillInSelectionList(Form, CheckKind)
	
	Form.Items.Goods_ResearchQualityIndicator.ChoiceList.Clear();
	
	ChoiceList = QualityIndicatorGetSelectionList(CheckKind);
	
	For Each ListItem In ChoiceList Do
		Form.Items.Goods_ResearchQualityIndicator.ChoiceList.Add(
			ListItem.Value, ListItem.Presentation);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function QualityIndicatorGetSelectionList(CheckKind)
	
	Return GoodsResearch.IndicatorGetSelectionList(CheckKind);
	
EndFunction

#EndRegion

#Region QualityControlAct

&AtServer
Function GetParametersOfQualityControlReportForm()
	
	FillingData = New Structure;
	FillingData.Insert("DocumentBasis", Object.RequestForControl);
	FillingData.Insert("DocumentResearch", Object.Ref);
	FillingData.Insert("Control", Object.Control);
	
	FormParameters = New Structure("Basis", FillingData);
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure IssueQualityControlReportCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	WriteParameters = New Structure;
	WriteParameters.Insert("WriteMode", DocumentWriteMode.Posting);
	WriteParameters.Insert("PostingMode", DocumentPostingMode.Regular);
	WriteParameters.Insert("NewObject", Not ValueIsFilled(Object.Ref));
	
	If Write(WriteParameters) Then
		OpenQualityControlReport();
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenQualityControlReport()
	
	If Object.PlanAndResearchResult.Total("QuantityAppropriate") = 0
		And Object.PlanAndResearchResult.Total("QuantityRejectable") = 0
		And Object.PlanAndResearchResult.Total("QuantityDamaged") = 0 Then
		ShowMessageBox(, NStr("vi = 'Chưa điền kết quả kiểm nghiệm, lệnh không thể thực hiện.';
								|ru = 'Не заполнен результат исследования, команда не может быть выполнена.';
								|en = 'The research result is not filled in. Cannot run the command.'; fa = 'The research result is not filled in. Cannot run the command.';
								|it = 'The research result is not filled in. Cannot run the command.';
								|pl = 'The research result is not filled in. Cannot run the command.';
								|tr = 'İnceleme sonucu doldurulmamış, komut gerçekleştirilemez.'"));
		Return;
	EndIf;
	
	ExistingResearchActs = CompletedResearchReports(Object.Ref);
	If ExistingResearchActs.Count() > 0 Then
		MessageTemplate = NStr("vi = 'Đã có biên bản được tạo cho kiểm nghiệm: ""%1"".';
								|ru = 'По исследованию уже создан акт: ""%1"".';
								|en = 'The certificate is already created for the research: ""%1"".'; fa = 'The certificate is already created for the research: ""%1"".';
								|it = 'The certificate is already created for the research: ""%1"".';
								|pl = 'The certificate is already created for the research: ""%1"".';
								|tr = 'İnceleme için zaten tutanak oluşturulmuş: ""%1"".'");
		For Each String In ExistingResearchActs Do
				MessageText = StrTemplate(MessageTemplate, String);
				CommonClient.MessageToUser(
					MessageText, , , , True);
		EndDo;
		Return;
	EndIf;
	
	FormParameters = GetParametersOfQualityControlReportForm();
	
	If FormParameters <> Undefined Then
		OpenForm("Document.GoodsQualityControlCertificate.Form.DocumentForm", FormParameters);
	EndIf;
	
EndProcedure

&AtServer
Function CheckImplementationOfResearchPlan(Cancel)

	ErrorMessages = New Array;

	MessageTemplate = NStr(
		"vi = 'Chưa thực hiện kế hoạch kiểm nghiệm tại dòng %1 của phần bảng ""%2"": số lượng cần kiểm nghiệm không khớp với số lượng hàng hóa đã kiểm nghiệm.';
		|ru = 'Не выполнен план исследования в строке %1 табличной части ""%2"" количество к исследованию не соответствует количеству исследованных товаров.';
		|en = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the quantity for research does not correspond to the number of researched goods.'; fa = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the quantity for research does not correspond to the number of researched goods.';
		|it = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the quantity for research does not correspond to the number of researched goods.';
		|pl = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the quantity for research does not correspond to the number of researched goods.';
		|tr = '""%2"" tablo bölümü %1 satırında inceleme planı gerçekleştirilmemiş: inceleme miktarı, incelenen ürün miktarıyla uyuşmuyor.'");
	MessageTemplateIsDestroyed = NStr(
		"vi = 'Chưa thực hiện kế hoạch kiểm nghiệm tại dòng %1 của phần bảng ""%2"": số lượng ""Đã hủy"" không thể lớn hơn số lượng ""Không đạt chất lượng"".';
		|ru = 'Не выполнен план исследования в строке %1 табличной части ""%2"" количество ""Разрушено"" не может быть больше количества ""Не удовлетворяющее качеству"".';
		|en = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.'; fa = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
		|it = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
		|pl = 'The research plan is not fulfilled: in row %1 of the ""%2"" table, the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
		|tr = '""%2"" tablo bölümü %1 satırında inceleme planı gerçekleştirilmemiş: ""İmha edilen"" miktarı, ""Kaliteye uygun olmayan"" miktarından büyük olamaz.'");

	If Object.Completed Then
		For Each TSRow In Object.PlanAndResearchResult Do
			If Not (TSRow.NumberOfPackages = TSRow.QuantityAppropriate
				+ TSRow.QuantityRejectable And TSRow.NumberOfPackages >= TSRow.QuantityDamaged) Then
				If ExploreMultipleGoods Then
					MessageText = StrTemplate(MessageTemplate, TSRow.LineNumber, NStr(
					"vi = 'Kế hoạch và kết quả nghiên cứu';
					|ru = 'План и результат исследования';
					|en = 'Plan and research result'; fa = 'برنامه و نتیجه بررسی';
					|it = 'Plan and research result';
					|pl = 'Plan and research result';
					|tr = 'İnceleme planı ve sonucu'"));
				Else
					MessageText = NStr(
						"vi = 'Chưa thực hiện kế hoạch kiểm nghiệm: số lượng cần kiểm nghiệm không khớp với số lượng hàng hóa đã kiểm nghiệm.';
						|ru = 'Не выполнен план исследования: количество к исследованию не соответствует количеству исследованных товаров.';
						|en = 'The research plan is not fulfilled: the quantity for research does not correspond to the number of researched goods.'; fa = 'The research plan is not fulfilled: the quantity for research does not correspond to the number of researched goods.';
						|it = 'The research plan is not fulfilled: the quantity for research does not correspond to the number of researched goods.';
						|pl = 'The research plan is not fulfilled: the quantity for research does not correspond to the number of researched goods.';
						|tr = 'İnceleme planı gerçekleştirilmemiş: inceleme miktarı, incelenen ürün miktarıyla uyuşmuyor.'");
				EndIf;
				ErrorStructure = New Structure;
				ErrorStructure.Insert("MessageText", MessageText);
				ErrorStructure.Insert("Field", CommonClientServer.PathToTabularSection(
					"Object.PlanAndResearchResult", TSRow.LineNumber, "NumberOfPackages"));
				ErrorMessages.Add(ErrorStructure);
				Cancel = True;
			EndIf;
			If Object.Control = Enums.QualityControl.Solid And (TSRow.QuantityDamaged
				> TSRow.QuantityRejectable) Then
				If ExploreMultipleGoods Then
					MessageText = StrTemplate(MessageTemplateIsDestroyed, TSRow.LineNumber, NStr(
					"vi = 'Kế hoạch và kết quả nghiên cứu';
					|ru = 'План и результат исследования';
					|en = 'Plan and research result'; fa = 'برنامه و نتیجه بررسی';
					|it = 'Plan and research result';
					|pl = 'Plan and research result';
					|tr = 'İnceleme planı ve sonucu'"));
				Else
					MessageText = NStr(
						"vi = 'Chưa thực hiện kế hoạch nghiên cứu: số lượng ""Đã hủy"" không thể lớn hơn số lượng ""Không đạt chất lượng"".';
						|ru = 'Не выполнен план исследования: количество ""Разрушено"" не может быть больше количества ""Не удовлетворяющее качеству"".';
						|en = 'The research plan is not fulfilled: the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.'; fa = 'The research plan is not fulfilled: the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
						|it = 'The research plan is not fulfilled: the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
						|pl = 'The research plan is not fulfilled: the ""Damaged"" quantity cannot be greater than the ""Not satisfying quality"" quantity.';
						|tr = 'İnceleme planı gerçekleştirilmemiş: ""İmha edilen"" miktarı, ""Kaliteye uygun olmayan"" miktarından büyük olamaz.'");
				EndIf;
				ErrorStructure = New Structure;
				ErrorStructure.Insert("MessageText", MessageText);
				ErrorStructure.Insert("Field", CommonClientServer.PathToTabularSection(
					"Object.PlanAndResearchResult", TSRow.LineNumber, "NumberOfPackages"));
				ErrorMessages.Add(ErrorStructure);
				Cancel = True;
			EndIf;
		EndDo;
	EndIf;

	Return ErrorMessages;

EndFunction

&AtServer
Function CompletedResearchReports(Ref)
	
	QueryText = "SELECT DISTINCT
	|	GoodsQualityControlCertificateResearchResults.Ref AS Ref
	|FROM
	|	Document.GoodsQualityControlCertificate.ResearchResults AS GoodsQualityControlCertificateResearchResults
	|WHERE
	|	GoodsQualityControlCertificateResearchResults.ResearchProject = &ResearchProject
	|	AND GoodsQualityControlCertificateResearchResults.Ref.Posted = TRUE";
	
	Query = New Query(QueryText);
	Query.SetParameter("ResearchProject", Ref);
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

#EndRegion

#Region VisibilityManagement

&AtServer
Procedure SetConditionalAppearance()
	
	#Region StandardAppearance
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "PlanAndResearchResultProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.PlanAndResearchResult.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
		
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
		"PlanAndResearchResultCharacteristic",
		"Object.PlanAndResearchResult.ItemVariantsAreUsed");
		
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"PlanAndResearchResultSeries",
		"Object.PlanAndResearchResult.BatchesIndicationStatus",
		"Object.PlanAndResearchResult.ItemsType");
	
	// Goods Research
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
		"Goods_ResearchCharacteristic",
		"Object.Goods_Research.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		"Goods_ResearchSeries",
		"Object.Goods_Research.BatchesIndicationStatus",
		"Object.Goods_Research.ItemsType");
		
	#EndRegion
	
EndProcedure

&AtServer
Procedure UpdateInformationOnUseOfBatchCharacteristics()
	
	If ExploreMultipleGoods Or Object.PlanAndResearchResult.Count() = 0 Then
		Return;
	EndIf;

	TableRow = Object.PlanAndResearchResult[0];
	ItemVariantsAreUsed = TableRow.ItemVariantsAreUsed;
	SeriesAreUsed = GoodsResearch.UsingSeries(TableRow.Products);
	If SeriesAreUsed Then
		RowsToProcess = New Array;
		RowsToProcess.Add(TableRow);
		ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["PlanAndResearchResult"],
			RowsToProcess);
		If TableRow.BatchesIndicationStatus = 0 Then
			SeriesAreUsed = False;
		EndIf;
	EndIf;
	
	// One Item
	If ItemVariantsAreUsed Then
		Items.PlanAndResearchResultCharacteristic1.Enabled = True;
		Items.PlanAndResearchResultCharacteristic1.InputHint = "";
		Items.PlanAndResearchResultCharacteristic1.AutoMarkIncomplete = True;
	Else
		Items.PlanAndResearchResultCharacteristic1.Enabled = False;
		Items.PlanAndResearchResultCharacteristic1.InputHint = NStr("vi = '<không sử dụng đặc tính>';
																	|ru = '<характеристики не используются>';
																	|en = '<variants are not used>'; fa = '<گونه‌ها استفاده نمی‌شوند>';
																	|it = '<le caratteristiche non vengono usate>';
																	|pl = '<charakterystyki nie dotyczą>';
																	|tr = '<varyantlar kullanılmamaktadır>'");
		Items.PlanAndResearchResultCharacteristic1.AutoMarkIncomplete = False;
	EndIf;
	
	If SeriesAreUsed Then
		Items.PlanAndResearchResultSeries1.Enabled = True;
		Items.PlanAndResearchResultSeries1.InputHint = "";
		Items.PlanAndResearchResultCharacteristic1.AutoMarkIncomplete = True;
	Else
		Items.PlanAndResearchResultSeries1.Enabled = False;
		Items.PlanAndResearchResultSeries1.InputHint = NStr("vi = '<không sử dụng sê-ri>';
															|ru = '<серии не используются>';
															|en = '<batches are not used>'; fa = '<batches are not used>';
															|it = '<le serie non sono utilizzate>';
															|pl = '<serie nie są używane>';
															|tr = '<partiler kullanılmamaktadır>'");
		Items.PlanAndResearchResultSeries1.AutoMarkIncomplete = False;
	EndIf;
	
	Items.SpecifySeries.Enabled = SeriesAreUsed;
	Items.BatchesIndicationStatus.Enabled = SeriesAreUsed;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("FormType")
		Or Initialize Then
		OneStudy = Object.PlanAndResearchResult.Count() <= 1;
		Items.Goods_ResearchProducts.Visible = Not OneStudy;
		Items.Goods_ResearchCharacteristic.Visible = Not OneStudy;
		If OneStudy And Not Form.ExploreMultipleGoods Then
			Items.PagesDisplayPlanAndResultOfStudy.CurrentPage = Items.PageOneItem;
		Else
			Items.PagesDisplayPlanAndResultOfStudy.CurrentPage = Items.MultipleItemItemsPage;
		EndIf;
		Items.ExploreMultipleGoods.Enabled = OneStudy And Form.ItemsAvailability;
	EndIf;
	
	If AttributesStructure1.Property("GoodsResearchSheet")
		Or Initialize Then
		
		StudyIsCompleted = Object.Completed;
		StudyCardIsNotFilledIn = Not ValueIsFilled(Object.GoodsResearchSheet);
		AvailabilityVisibilityCondition = StudyCardIsNotFilledIn Or StudyIsCompleted;
		Items.PlanAndResearchResult.ReadOnly = AvailabilityVisibilityCondition;
		Items.Goods_Research.ReadOnly = AvailabilityVisibilityCondition;
		Items.RadioButton.ReadOnly = AvailabilityVisibilityCondition;
		Items.Control.ReadOnly = AvailabilityVisibilityCondition;
		Items.GroupSamples.ReadOnly = AvailabilityVisibilityCondition;
		Items.GroupOneItem.ReadOnly = AvailabilityVisibilityCondition;
		
		// Commands
		Items.FillInResult.Enabled = Not AvailabilityVisibilityCondition;
		Items.FillInResearchResult.Enabled = Not AvailabilityVisibilityCondition;
		Items.GoodsInsertRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.GoodsCopyRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.PickUpChecks.Enabled = Not AvailabilityVisibilityCondition;
		Items.SelectGoods.Enabled = Not AvailabilityVisibilityCondition;
		Items.SplitRow.Enabled = Not AvailabilityVisibilityCondition;
		Items.InsertRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.CopyRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.SearchByBarcode.Enabled = Not AvailabilityVisibilityCondition;
		
		// Hyperlinks
		Items.DecorationAddSample.Enabled = Not AvailabilityVisibilityCondition And Form.ItemsAvailability;
		Items.DecorationChoosePattern.Enabled = Not AvailabilityVisibilityCondition And Form.ItemsAvailability;
		Items.DecorationAllSamples.Enabled = Not AvailabilityVisibilityCondition;
		
	EndIf;
	
	If AttributesStructure1.Property("Control")
		Or Initialize Then
		
		TypeOfControlIsSelective = Object.Control = PredefinedValue(
			"Enum.QualityControl.Selective");
		MethodOfVerificationIsSummary = Object.InstancesCheckMethod = PredefinedValue(
			"Enum.CheckOptionsOfResearchCopies.Overall");
			
		Items.RadioButton.Visible = Not TypeOfControlIsSelective;
		Items.GroupSamples.Visible 				= TypeOfControlIsSelective;
		Items.GoodsResearchLineNumber.Visible 	= TypeOfControlIsSelective;
		Items.Goods_ResearchPattern.Visible 	= TypeOfControlIsSelective;
		Items.Goods_ResearchDamaged.Visible 		= TypeOfControlIsSelective;
		
		Items.PickUpChecks.Visible = Not TypeOfControlIsSelective;
		
		If Not TypeOfControlIsSelective Then

			Items.GroupSamples.Visible 				= Not MethodOfVerificationIsSummary;
			Items.GoodsResearchLineNumber.Visible 	= Not MethodOfVerificationIsSummary;
			Items.Goods_ResearchPattern.Visible 	= Not MethodOfVerificationIsSummary;
			Items.Goods_ResearchDamaged.Visible 		= Not MethodOfVerificationIsSummary;
			Items.PickUpChecks.Visible 				= MethodOfVerificationIsSummary;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("InstancesCheckMethod")
		Or Initialize Then
			
			MethodOfVerificationIsSummary = Object.InstancesCheckMethod = PredefinedValue(
				"Enum.CheckOptionsOfResearchCopies.Overall");

			Items.GroupSamples.Visible 				= Not MethodOfVerificationIsSummary;
			Items.GoodsResearchLineNumber.Visible 	= Not MethodOfVerificationIsSummary;
			Items.Goods_ResearchPattern.Visible 	= Not MethodOfVerificationIsSummary;
			Items.Goods_ResearchDamaged.Visible 		= Not MethodOfVerificationIsSummary;
			Items.PickUpChecks.Visible 				= MethodOfVerificationIsSummary;
			Items.Goods_ResearchCount.Visible	= Not MethodOfVerificationIsSummary;
			
			NewParameter1 = New ChoiceParameter("InstancesCheckMethod", Object.InstancesCheckMethod);
			NewArray = New Array;
			NewArray.Add(NewParameter1);
			NewParameter1 = New FixedArray(NewArray);
			Items.Goods_ResearchResult.ChoiceParameters = NewParameter1;
		
	EndIf;
	
	If AttributesStructure1.Property("Filter")
		Or Initialize Then
		
		If Form.ShowAllInstances Then
			Items.DecorationChoosePattern.Title = NStr("vi = 'Chọn mẫu';
														|ru = 'Отобрать образец';
														|en = 'Select template'; fa = 'انتخاب الگو';
														|it = 'Select template';
														|pl = 'Select template';
														|tr = 'Örnek seç'");
			SetStateOfHyperlink(Form, Items.DecorationAllSamples, False);
			Items.Goods_ResearchMoveUp.Enabled = True;
			Items.Goods_ResearchMoveDown.Enabled = True;
		Else
			SetStateOfHyperlink(Form, Items.DecorationAllSamples, True);
			Items.Goods_ResearchMoveUp.Enabled = False;
			Items.Goods_ResearchMoveDown.Enabled = False;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Status")
		Or Initialize Then
		
		StudyIsCompleted = Object.Completed;
		OneStudy = Object.PlanAndResearchResult.Count() <= 1;
		StudyCardIsNotFilledIn = Not ValueIsFilled(Object.GoodsResearchSheet);
		AvailabilityVisibilityCondition = StudyIsCompleted Or StudyCardIsNotFilledIn;
		Items.PlanAndResearchResult.ReadOnly = AvailabilityVisibilityCondition;
		Items.Goods_Research.ReadOnly = AvailabilityVisibilityCondition;
		Items.GoodsResearchSheet.ReadOnly = StudyIsCompleted;
		Items.EmployeeResponsible.ReadOnly = StudyIsCompleted;
		Items.RadioButton.ReadOnly = AvailabilityVisibilityCondition;
		Items.Control.ReadOnly = AvailabilityVisibilityCondition;
		Items.GroupSamples.ReadOnly = AvailabilityVisibilityCondition;
		Items.GroupOneItem.ReadOnly = AvailabilityVisibilityCondition;
		Items.ExploreMultipleGoods.Enabled = Not StudyIsCompleted And OneStudy
			And Form.ItemsAvailability;
		
		// Commands
		Items.FillInResult.Enabled = Not AvailabilityVisibilityCondition;
		Items.FillInResearchResult.Enabled = Not AvailabilityVisibilityCondition;
		Items.GoodsInsertRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.GoodsCopyRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.PickUpChecks.Enabled = Not AvailabilityVisibilityCondition;
		Items.SelectGoods.Enabled = Not AvailabilityVisibilityCondition;
		Items.SplitRow.Enabled = Not AvailabilityVisibilityCondition;
		Items.InsertRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.CopyRows.Enabled = Not AvailabilityVisibilityCondition;
		Items.SearchByBarcode.Enabled = Not AvailabilityVisibilityCondition;
		Items.IssueQualityControlReport.Visible = StudyIsCompleted;
		
		// Hyperlinks
		Items.DecorationAddSample.Enabled = Not AvailabilityVisibilityCondition And Form.ItemsAvailability;
		Items.DecorationChoosePattern.Enabled = Not AvailabilityVisibilityCondition And Form.ItemsAvailability;
		Items.DecorationAllSamples.Enabled = Not AvailabilityVisibilityCondition;
		
	EndIf;
	
	If AttributesStructure1.Property("ItemOfSample")
		Or Initialize Then
		
		Items.ItemOfSample.Visible = Form.ExploreMultipleGoods;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetStateOfHyperlink(Form, Item, Clicked)
	
	If Clicked Then
		Item.TextColor = Form.Cache.ColorOfClickedHyperlink;
	Else
		Item.TextColor = Form.Cache.ColorOfNonClickedHyperlink;
	EndIf;
	
EndProcedure

#EndRegion

#Region CommandService

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer(SelectedRows, TableName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TableName], SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns =
		"Products,
		|Characteristic,
		|Purpose,
		|ControlledLotReference,
		|Series,
		|Warehouse,
		|Count,
		|QuantityAppropriate,
		|QuantityDamaged,
		|QuantityRejectable,
		|GoodsResearchSheet,
		|Package,
		|NumberOfPackages";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	RowsToProcess = New Array();
	For Each RowOfProduct In TableOfGoods Do
		
		TableRow = Object.PlanAndResearchResult.Add();
		FillPropertyValues(TableRow, RowOfProduct);
		TableRow.RowID = New UUID;
		RowsToProcess.Add(TableRow);
		
	EndDo;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["PlanAndResearchResult"]);
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "PlanAndResearchResult");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.PlanAndResearchResult,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["PlanAndResearchResult"], RowsToProcess);
	
EndProcedure

&AtServer
Procedure GetLinesFromResearchClipboard()
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType",
		ProductsClientServer.SelectionByProductMultiTurnContainer(False));
	
	Columns =
		"Products,
		|Characteristic,
		|Series,
		|Pattern,
		|CheckKind,
		|QualityIndicator,
		|Count,
		|Norm,
		|Real,
		|LongDesc,
		|Result,
		|RowID,
		|InstanceId";
	
	TableOfGoods = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;
	
	ItemList = ItemUsedIsPlanAndResultOfStudy();
	RowsToProcess = New Array();
	For Each RowOfProduct In TableOfGoods Do

		TableRow = Object.Goods_Research.Add();
		FillPropertyValues(TableRow, RowOfProduct);
		RowsToProcess.Add(TableRow);

		FoundProducts = ItemList.Find(RowOfProduct.Products);
		If FoundProducts = Undefined Then
			TableRow.Products = Catalogs.Products.EmptyRef();
		EndIf;

	EndDo;
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["Goods_Research"]);
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "Goods_Research");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods_Research,
		CachedValues);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["Goods_Research"], RowsToProcess);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("InsertRows");
	ItemArray.Add("PlanAndResultOfStudyContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("InsertRows");
	ItemArray.Add("PlanAndResultOfStudyContextMenuInsertLines");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtClient
Procedure SplitRowCompletion(NewRow, AdditionalParameters) Export 
	
	CurrentRow = Items.PlanAndResearchResult.CurrentData;
	
	If NewRow <> Undefined Then
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("RecalculateNumberOfUnits");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
		BatchProcessingOfTablePartClient.ProcessTSString(NewRow, StructureOfActions, CachedValues);
				
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "FormType");
	
EndProcedure

&AtClient
Procedure FillInQualityControlResultAfterSelection(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Then
		Return;
	EndIf;
	FillInQualityControlResultAfterSelectionServer(ValueSelected);
	
EndProcedure

&AtServer
Procedure FillInQualityControlResultAfterSelectionServer(ValueSelected)
	
	For Each Id In Items.PlanAndResearchResult.SelectedRows Do
		
		Object.PlanAndResearchResult.FindByID(Id).QualityCheckResult = ValueSelected;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInByBalanceServer(Val SettingsComposer)
	
	Object.PlanAndResearchResult.Clear();
	FillingSettingsByBalance.LoadSettings(SettingsComposer.GetSettings());
	FillingSettingsByBalance.LoadUserSettings(SettingsComposer.UserSettings);
	
	DataCompositionSchema = Documents.RequestForGoodsQualityControl.GetTemplate("FillingSchemeByBalances");
	CompositionSettings = FillingSettingsByBalance.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
		CompositionSettings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate);
	OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
	Analysts = OutputProcessor.Output(CompositionProcessor);
	Object.PlanAndResearchResult.Load(QualityControl.AnalystBalances(Analysts, True, Object.Date));
	
EndProcedure

&AtClient
Procedure SettingUpFillingByBalanceEnd(ClosingResult, AdditionalParameters) Export

	If TypeOf(ClosingResult) = Type("DataCompositionSettingsComposer") Then
		FillInByBalanceServer(ClosingResult);
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	TableOfGoods = GetFromTempStorage(ValueSelected.GoodsAddressInStorage);
	
	If Not ValueIsFilled(TableOfGoods) Then
		Return;
	EndIf;

	RowsToProcess = New Array;
	For Each RowOfProduct In TableOfGoods Do

		TableRow = Object.PlanAndResearchResult.Add();
		RowsToProcess.Add(TableRow);
		TableRow.RowID = New UUID();
		FillPropertyValues(TableRow, RowOfProduct,
			"Products,Characteristic,Package,NumberOfPackages,Series");

	EndDo;

	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName", FormName,
		"PlanAndResearchResult");

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActions.Insert("CheckCharacteristicsByOwner", TableRow.Characteristic);
	StructureOfActions.Insert("RecalculateNumberOfUnits");

	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
			RowsToProcess, StructureOfActions, Object.PlanAndResearchResult, CachedValues);

	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["PlanAndResearchResult"], RowsToProcess);

EndProcedure

&AtClient
Procedure ResearchPlanAndResultBarcodeSearchEnd(BarcodeData_2, AdditionalParameters) Export
	
	ProcessBarcodes(BarcodeData_2);
	
EndProcedure

&AtClient
Procedure ProcessBarcodes(BarcodeData_5)
	
	ClearMessages();
	
	If Not BarcodingOfItemsClient.BarcodesAreValid(BarcodeData_5) Then
		Return;
	EndIf;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");

	ProductsOnChangeOverridable = New Structure("FormName, TabularSectionName",
		FormName, "PlanAndResearchResult");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["PlanAndResearchResult"]);
	
	StructureOfActionsWithAddedStrings = New Structure();
	StructureOfActionsWithAddedStrings.Insert("FillInArticleAttribute", FillInArticleAttribute);
	StructureOfActionsWithAddedStrings.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActionsWithAddedStrings.Insert("ProductsOnChangeOverridable", ProductsOnChangeOverridable);
	StructureOfActionsWithAddedStrings.Insert("RecalculateNumberOfUnits");
	StructureOfActionsWithAddedStrings.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	StructureOfActionsWithModifiedStrings = New Structure();
	StructureOfActionsWithModifiedStrings.Insert("RecalculateNumberOfUnits");
	
	BarcodeProcessingParameters = BarcodingOfItemsClient.BarcodeProcessingParameters();
	
	BarcodeProcessingParameters.Barcodes = BarcodeData_5;
	BarcodeProcessingParameters.StructureOfActionsWithAddedStrings = StructureOfActionsWithAddedStrings;
	BarcodeProcessingParameters.StructureOfActionsWithModifiedStrings = StructureOfActionsWithModifiedStrings;
	BarcodeProcessingParameters.SeriesSpecificationParameters = SeriesSpecificationParameters["PlanAndResearchResult"];
	BarcodeProcessingParameters.ChangeQuantity = True;
	BarcodeProcessingParameters.GoodsOnly = True;
	BarcodeProcessingParameters.TSName = "PlanAndResearchResult";
	
	ProcessBarcodesServer(BarcodeProcessingParameters, CachedValues);
	
	BarcodingOfItemsClient.ProcessUnknownBarcodes(BarcodeProcessingParameters,
		CachedValues, ThisObject);
	
	If BarcodingOfItemsClient.YouNeedToOpenFormForSpecifyingSeriesAfterProcessingBarcodes(BarcodeProcessingParameters) Then
		CurDataId = BarcodeProcessingParameters.ArrayOfRowsWithSeries_[0];
		AttachIdleHandler("OpenSeriesSelectionWhenScanningProductBarCode", 0.1, True);
	EndIf;

	If BarcodeProcessingParameters.CurrentRow <> Undefined Then
		Items.PlanAndResearchResult.CurrentRow = BarcodeProcessingParameters.CurrentRow;
	EndIf;
	
	If Object.PlanAndResearchResult.Count() > 1 Then
		ExploreMultipleGoods = True; 
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "FormType");
	
EndProcedure

&AtServer
Procedure ProcessBarcodesServer(StructureOfActionParameters, CachedValues)
	
	ItemsTypes = ProductsServer.AcceptableItemTypesToChooseFrom(
		Enums.BusinessTransactions.GoodsQualityControl);
	
	ThereAreWorks = ItemsTypes.Find(Enums.ItemsTypes.Work_5) <> Undefined;
	ThereAreServices = ItemsTypes.Find(Enums.ItemsTypes.OperationService) <> Undefined;
	
	StructureOfActionParameters.GoodsOnly = Not (ThereAreWorks Or ThereAreServices);
	StructureOfActionParameters.OnlyGoodsAndWork = ThereAreWorks And Not ThereAreServices;
	StructureOfActionParameters.OnlyGoodsAndServices = ThereAreServices And Not ThereAreWorks;
	
	BarcodingOfItemsServer.ProcessBarcodes(ThisObject,
		Object, StructureOfActionParameters, CachedValues);
	
EndProcedure

&AtServer
Procedure PickUpChecksAtServer()
	
	RowsToProcess = New Array();
	
	For Each TableRow In Object.PlanAndResearchResult Do
		
		InstanceId = New UUID;
	
		For Each CheckString In Checks Do

			NewRow = Object.Goods_Research.Add();
			FillPropertyValues(NewRow, TableRow);
			FillPropertyValues(NewRow, CheckString);
			NewRow.InstanceId = InstanceId;
			RowsToProcess.Add(NewRow);
			
		EndDo;

	EndDo;
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["Goods_Research"]);
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods_Research,
		CachedValues);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure SetResultToEnd(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SetPropsValueToAllLines("Result", Result, AdditionalParameters.RowID);

EndProcedure

&AtServer
Procedure FillInResearchResult()

	TableOfCalculationOfResearchResult = New ValueTable;
	TableOfCalculationOfResearchResult.Columns.Add("Products");
	TableOfCalculationOfResearchResult.Columns.Add("Characteristic");
	TableOfCalculationOfResearchResult.Columns.Add("Series");
	TableOfCalculationOfResearchResult.Columns.Add("InstanceId");
	TableOfCalculationOfResearchResult.Columns.Add("IsPassed");
	TableOfCalculationOfResearchResult.Columns.Add("NotPassed");
	TableOfCalculationOfResearchResult.Columns.Add("IsDestroyed");
	TableOfCalculationOfResearchResult.Columns.Add("StudyIsCompleted");

	TableToSearch = Object.PlanAndResearchResult.Unload( , "Products,Characteristic,Series");
	TableToSearch.GroupBy("Products,Characteristic,Series");

	For Each TableRow In TableToSearch Do

		Filter = New Structure;
		Filter.Insert("Products", TableRow.Products);
		Filter.Insert("Characteristic", TableRow.Characteristic);
		If ValueIsFilled(TableRow.Series) Then
			Filter.Insert("Series", TableRow.Series);
		EndIf;

		FoundStudies = Object.Goods_Research.FindRows(Filter);
		If FoundStudies.Count() = 0 Then
			Continue;
		EndIf;

		For Each ArrayRow In FoundStudies Do

			InstanceCalculation = TableOfCalculationOfResearchResult.FindRows(
				New Structure("InstanceId", ArrayRow.InstanceId));
			If InstanceCalculation.Count() = 0 Then
				NewRow = TableOfCalculationOfResearchResult.Add();
				NewRow.Products = ArrayRow.Products;
				NewRow.Characteristic = ArrayRow.Characteristic;
				If ValueIsFilled(TableRow.Series) Then
					NewRow.Series = TableRow.Series;
				Else
					NewRow.Series = ArrayRow.Series;
				EndIf;
				NewRow.InstanceId = ArrayRow.InstanceId;
				NewRow.IsPassed = 0;
				NewRow.NotPassed = 0;
				NewRow.IsDestroyed = 0;
				NewRow.StudyIsCompleted = True;
				If Not ValueIsFilled(ArrayRow.Result) Then
					NewRow.StudyIsCompleted = False;
				Else
					If ArrayRow.Result = Enums.GoodsResearchResult.IsPassed Then
						NewRow.IsPassed = ArrayRow.Count;
					ElsIf ArrayRow.Result
						= Enums.GoodsResearchResult.PassedWithOtherQuality Then
						NewRow.NotPassed = ArrayRow.Count;
					ElsIf ArrayRow.Result = Enums.GoodsResearchResult.NotPassed Then
						NewRow.NotPassed = ArrayRow.Count;
					EndIf;
					If ArrayRow.Damaged Then
						NewRow.IsDestroyed = ArrayRow.Count;
					EndIf;
				EndIf;
			Else
				FoundInstance = InstanceCalculation[0];

				If Not ValueIsFilled(ArrayRow.Result) Or FoundInstance.StudyIsCompleted = False Then
					FoundInstance.StudyIsCompleted = False;
				Else
					If ArrayRow.Result = Enums.GoodsResearchResult.IsPassed
						And FoundInstance.NotPassed = 0 Then
						FoundInstance.IsPassed = ArrayRow.Count;
					Else
						FoundInstance.IsPassed = 0;
					EndIf;

					If ArrayRow.Result = Enums.GoodsResearchResult.NotPassed
						Or ArrayRow.Result = Enums.GoodsResearchResult.PassedWithOtherQuality Then
						FoundInstance.NotPassed = ArrayRow.Count;
					EndIf;

					If ArrayRow.Damaged Then
						FoundInstance.IsDestroyed = ArrayRow.Count;
					EndIf;

				EndIf;
			EndIf;

		EndDo;

	EndDo;

	If TableOfCalculationOfResearchResult.Count() = 0 Then
		Return;
	EndIf;

	For Each ResultRow In Object.PlanAndResearchResult Do
		If Object.Control = Enums.QualityControl.Solid
			And Object.InstancesCheckMethod = Enums.CheckOptionsOfResearchCopies.WithVariances Then
			ResultRow.QuantityAppropriate = ResultRow.NumberOfPackages;
		Else
			ResultRow.QuantityAppropriate = 0;
		EndIf;
		ResultRow.QuantityDamaged = 0;
		ResultRow.QuantityRejectable = 0;
	EndDo;

	If Object.Control = Enums.QualityControl.Solid
		And Object.InstancesCheckMethod = Enums.CheckOptionsOfResearchCopies.Overall Then
		For Each CountingLine In TableOfCalculationOfResearchResult Do
			Filter = New Structure;
			Filter.Insert("Products", CountingLine.Products);
			Filter.Insert("Characteristic", CountingLine.Characteristic);
			Filter.Insert("Series", CountingLine.Series);
			FoundLinesOfResearchPlan = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundLinesOfResearchPlan.Count() <> 0 Then
				For Each ResultRow In FoundLinesOfResearchPlan Do
					If CountingLine.StudyIsCompleted Then
						If CountingLine.NotPassed <> 0 Then
							ResultRow.QuantityRejectable = ResultRow.NumberOfPackages;
							ResultRow.QuantityAppropriate = 0;
						ElsIf CountingLine.IsPassed <> 0 And ResultRow.QuantityRejectable = 0 Then
							ResultRow.QuantityAppropriate = ResultRow.NumberOfPackages;
						EndIf;
					Else
						ResultRow.Result = False;
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		
	ElsIf Object.Control = Enums.QualityControl.Solid
		And Object.InstancesCheckMethod = Enums.CheckOptionsOfResearchCopies.WithVariances Then
		For Each CountingLine In TableOfCalculationOfResearchResult Do
			NotCompletedYet = CountingLine.NotPassed;
			ItRemainsDestroyed = CountingLine.IsDestroyed;
			Filter = New Structure;
			Filter.Insert("Products", CountingLine.Products);
			Filter.Insert("Characteristic", CountingLine.Characteristic);
			Filter.Insert("Series", CountingLine.Series);
			FoundLinesOfResearchPlan = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundLinesOfResearchPlan.Count() <> 0 Then
				For Each ResultRow In FoundLinesOfResearchPlan Do
					Balance = ResultRow.NumberOfPackages
						- ResultRow.QuantityRejectable;
					If NotCompletedYet = 0 Or Balance <= 0 Then
						Break;
					EndIf;
					If CountingLine.StudyIsCompleted Then
						If Balance - NotCompletedYet > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate - NotCompletedYet;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
								NotCompletedYet, ItRemainsDestroyed);
							ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
							NotCompletedYet = 0;
							ItRemainsDestroyed = 0;
						Else
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate - Balance;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(Balance,
								ItRemainsDestroyed);
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed), 0);
						EndIf;
					EndIf;
				EndDo;
				If NotCompletedYet > 0 Then
					ResultRow = FoundLinesOfResearchPlan[FoundLinesOfResearchPlan.Count()
						- 1];
					ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
						NotCompletedYet, ItRemainsDestroyed);
					ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
				EndIf;
		// There are samples left where the batch is indicated for reference
			Else
				Filter = New Structure;
				Filter.Insert("Products", CountingLine.Products);
				Filter.Insert("Characteristic", CountingLine.Characteristic);
				Filter.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
				FoundLinesOfResearchPlan = Object.PlanAndResearchResult.FindRows(Filter);
				For Each ResultRow In FoundLinesOfResearchPlan Do
					Balance = ResultRow.NumberOfPackages - ResultRow.QuantityRejectable;
					If NotCompletedYet = 0 Or Balance <= 0 Then
						Break;
					EndIf;
					If CountingLine.StudyIsCompleted Then
						If Balance - NotCompletedYet > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate - NotCompletedYet;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
								NotCompletedYet, ItRemainsDestroyed);
							ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
							NotCompletedYet = 0;
							ItRemainsDestroyed = 0;
						Else
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate - Balance;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(Balance,
								ItRemainsDestroyed);
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed), 0);
						EndIf;
					EndIf;
				EndDo;
				If NotCompletedYet > 0 Then
					ResultRow = FoundLinesOfResearchPlan[FoundLinesOfResearchPlan.Count()
						- 1];
					ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
						NotCompletedYet, ItRemainsDestroyed);
					ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
				EndIf;
			EndIf;

		EndDo;

	Else

		For Each CountingLine In TableOfCalculationOfResearchResult Do
			ThereIsGoodOneLeft = CountingLine.IsPassed;
			NotCompletedYet = CountingLine.NotPassed;
			ItRemainsDestroyed = CountingLine.IsDestroyed;
			Filter = New Structure;
			Filter.Insert("Products", CountingLine.Products);
			Filter.Insert("Characteristic", CountingLine.Characteristic);
			Filter.Insert("Series", CountingLine.Series);
			FoundLinesOfResearchPlan = Object.PlanAndResearchResult.FindRows(Filter);
			If FoundLinesOfResearchPlan.Count() <> 0 Then
				For Each ResultRow In FoundLinesOfResearchPlan Do
					Balance = ResultRow.NumberOfPackages - ResultRow.QuantityAppropriate
						- ResultRow.QuantityRejectable;
					If (ThereIsGoodOneLeft + NotCompletedYet = 0) Or Balance <= 0 Then
						Break;
					EndIf;
					If CountingLine.StudyIsCompleted Then
						If Balance - ThereIsGoodOneLeft - NotCompletedYet > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(ThereIsGoodOneLeft
								+ NotCompletedYet, ItRemainsDestroyed);
							ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
							ThereIsGoodOneLeft = 0;
							NotCompletedYet = 0;
							ItRemainsDestroyed = 0;
						ElsIf Balance - ThereIsGoodOneLeft > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
								ThereIsGoodOneLeft, ItRemainsDestroyed);
							Balance = ResultRow.NumberOfPackages - ResultRow.QuantityAppropriate
								- ResultRow.QuantityRejectable;
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(ThereIsGoodOneLeft, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(ThereIsGoodOneLeft, ItRemainsDestroyed), 0);
							ThereIsGoodOneLeft = 0;
						Else
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + Balance;
							ThereIsGoodOneLeft = ThereIsGoodOneLeft - Balance;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(Balance,
								ItRemainsDestroyed);
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed), 0);
						EndIf;
					EndIf;
				EndDo;
				If ThereIsGoodOneLeft + NotCompletedYet > 0 Then
					ResultRow = FoundLinesOfResearchPlan[FoundLinesOfResearchPlan.Count()
						- 1];
					ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
					ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(ThereIsGoodOneLeft
						+ NotCompletedYet, ItRemainsDestroyed);
					ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
				EndIf;
		// There are samples left where the batch is indicated for reference
			Else
				Filter = New Structure;
				Filter.Insert("Products", CountingLine.Products);
				Filter.Insert("Characteristic", CountingLine.Characteristic);
				Filter.Insert("Series", Catalogs.ItemsBatches.EmptyRef());
				FoundLinesOfResearchPlan = Object.PlanAndResearchResult.FindRows(Filter);
				For Each ResultRow In FoundLinesOfResearchPlan Do
					Balance = ResultRow.NumberOfPackages - ResultRow.QuantityAppropriate
						- ResultRow.QuantityRejectable;
					If (ThereIsGoodOneLeft + NotCompletedYet = 0) Or Balance <= 0 Then
						Break;
					EndIf;
					If CountingLine.StudyIsCompleted Then
						If Balance - ThereIsGoodOneLeft - NotCompletedYet > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(ThereIsGoodOneLeft
								+ NotCompletedYet, ItRemainsDestroyed);
							ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
							ThereIsGoodOneLeft = 0;
							NotCompletedYet = 0;
							ItRemainsDestroyed = 0;
						ElsIf Balance - ThereIsGoodOneLeft > 0 Then
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(
								ThereIsGoodOneLeft, ItRemainsDestroyed);
							Balance = ResultRow.NumberOfPackages - ResultRow.QuantityAppropriate
								- ResultRow.QuantityRejectable;
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(ThereIsGoodOneLeft, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(ThereIsGoodOneLeft, ItRemainsDestroyed), 0);
							ThereIsGoodOneLeft = 0;
						Else
							ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + Balance;
							ThereIsGoodOneLeft = ThereIsGoodOneLeft - Balance;
							ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(Balance,
								ItRemainsDestroyed);
							ItRemainsDestroyed = ?(ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed) > 0,
								ItRemainsDestroyed - Min(Balance, ItRemainsDestroyed), 0);
						EndIf;
					EndIf;
				EndDo;
				If ThereIsGoodOneLeft + NotCompletedYet > 0 Then
					ResultRow = FoundLinesOfResearchPlan[FoundLinesOfResearchPlan.Count()
						- 1];
					ResultRow.QuantityAppropriate = ResultRow.QuantityAppropriate + ThereIsGoodOneLeft;
					ResultRow.QuantityDamaged = ResultRow.QuantityDamaged + Min(ThereIsGoodOneLeft
						+ NotCompletedYet, ItRemainsDestroyed);
					ResultRow.QuantityRejectable = ResultRow.QuantityRejectable + NotCompletedYet;
				EndIf;
			EndIf;

		EndDo;

	EndIf;
	
	UpdateResearchResult();

EndProcedure

&AtServer
Procedure UpdateResearchResult()

	For Each TSRow In Object.PlanAndResearchResult Do
		If TSRow.NumberOfPackages = TSRow.QuantityAppropriate
			+ TSRow.QuantityRejectable And TSRow.NumberOfPackages >= TSRow.QuantityDamaged Then
				TSRow.Result = True;
		Else
			TSRow.Result = False;
		EndIf;
	EndDo;

EndProcedure

#EndRegion

#Region Subsystems

// IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command,
		ThisObject, Object);
	
EndProcedure

// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

// StandardSubsystems.Properties 
&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region SetOfSeries

&AtClient
Procedure OpenSeriesSelectionWhenScanningProductBarCode()
	
	If CurDataId = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Object.Goods.FindByID(CurDataId);
	OpenSelectionOfSeries(,CurrentData);
	
EndProcedure

&AtClient
Procedure PickUpBatchesOnClient(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
		ThisObject,
		SeriesSpecificationParameters["Goods_Research"],
		Text,
		CurrentData);
		
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.Goods_Research.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, "Goods_Research");
		
		CurParametersForSpecifyingSeries = New Structure("ParametersOfSeriesIndicationForm", SeriesSpecificationParameters["Goods_Research"]);
		
		CallbackDescription = New CallbackDescription(
			"OpenSelectionOfSeriesCompletion",
			ThisObject,
			CurParametersForSpecifyingSeries);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSelectionOfSeries(Text = "", CurrentData = Undefined)
	
	NeedServerCall = ProductsClient.YouNeedServerCallToSpecifySeries(
		ThisObject,
		SeriesSpecificationParameters["PlanAndResearchResult"],
		Text,
		CurrentData);
		
	If NeedServerCall Then
		
		If CurrentData = Undefined Then
			CurDataId = Items.PlanAndResearchResult.CurrentData.GetID();
		Else
			CurDataId = CurrentData.GetID();
		EndIf;
		
		ParametersOfSeriesIndicationForm = ParametersOfSeriesIndicationForm(CurDataId, "PlanAndResearchResult");
		
		CurParametersForSpecifyingSeries = New Structure("ParametersOfSeriesIndicationForm", ParametersOfSeriesIndicationForm);
		
		CallbackDescription = New CallbackDescription(
			"OpenSelectionOfSeriesCompletion",
			ThisObject,
			CurParametersForSpecifyingSeries);
		
		OpenForm(
			ParametersOfSeriesIndicationForm.FormName,
			ParametersOfSeriesIndicationForm,
			ThisObject,
			,
			,
			,
			CallbackDescription,
			FormWindowOpeningMode.LockOwnerWindow);
			
	EndIf;
		
EndProcedure

&AtClient
Procedure OpenSelectionOfSeriesCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
		
	ParametersOfSeriesIndicationForm = AdditionalParameters.ParametersOfSeriesIndicationForm;
	TSName = ParametersOfSeriesIndicationForm.SeriesSpecificationParameters.TSName;
	
	ProcessSeriesIndication_Server(AdditionalParameters.ParametersOfSeriesIndicationForm, CachedValues, TSName);
	
EndProcedure

&AtServer
Procedure ProcessSeriesIndication_Server(ParametersOfSeriesIndicationForm, CachedValues, TSName)
	
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters[TSName]);
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	ProductsServer.ProcessSeriesIndication_(
		Object,
		SeriesSpecificationParameters[TSName],
		ParametersOfSeriesIndicationForm,
		StructureOfActions,
		CachedValues);
	
EndProcedure

&AtServer
Function ParametersOfSeriesIndicationForm(CurDataId, TSName)
	
	Return ProductsServer.ParametersOfSeriesIndicationForm(
		Object,
		SeriesSpecificationParameters[TSName],
		CurDataId,
		ThisObject);
	
EndFunction

#EndRegion

#Region ChangingDocumentAttributes

&AtServer
Procedure WarehouseWhenChangedOnServer()
	
	If ValueIsFilled(Object.Warehouse) Then
		
		CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["PlanAndResearchResult"]);
		
		StructureOfActions = New Structure();
		StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
		BatchProcessingOfTablePartServer.TreatTS(Object.PlanAndResearchResult, StructureOfActions);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsResearchSheetOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Object.GoodsResearchSheet = MapOfStudyBeforeChange;
		Return;
	EndIf;
	
	MapOfStudyBeforeChange = Object.GoodsResearchSheet;
	FillInServiceDetailsONChangingStudyCard();
	
	ConfigureDependentFormElements(ThisObject, "GoodsResearchSheet");
	
	Modified = True;

EndProcedure

&AtClient
Procedure TypeOfControlOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Object.Control = TypeOfControlBeforeChange;
		Return;
	EndIf;
	
	ClearResearchResults();
	
	Modified = True;

EndProcedure

#EndRegion

#Region Patterns

&AtClient
Procedure OpenAddSampleEndForm(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	LastAddedItem = Result.Products;
	LastAddedCharacteristic = Result.Characteristic;
	SampleName = Result.Pattern;
	
	If Not ShowAllInstances Then
		ItemResearchEstablishSelectionByInstance(SampleName);
	EndIf;
	
	AddInstanceAtServer();
	
	Modified = True;

EndProcedure

&AtClient
Procedure OpenSampleSelectionEndForm(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	ShowAllInstances = False;
	
	ItemResearchEstablishSelectionByInstance(Result.Pattern);

EndProcedure

&AtServer
Procedure ItemResearchEstablishSelectionByInstance(Pattern)
	
	ArrayOfIdentifiers = New Array;
	FoundRows = Object.Goods_Research.FindRows(New Structure("Pattern", Pattern));
	For Each String In FoundRows Do
		ArrayOfIdentifiers.Add(String.InstanceId);
	EndDo;
	
	ArrayOfIdentifiers = CommonClientServer.CollapseArray(ArrayOfIdentifiers);
	
	Filter = New Structure;
	Filter.Insert("InstanceId", ArrayOfIdentifiers);
	Items.Goods_Research.RowFilter = New FixedStructure(Filter);
	Items.Goods_Research.Refresh();
	
	If ExploreMultipleGoods Then
		ItemOfSample = "AllProducts";
	EndIf;
	
	FilterTemplate = NStr("vi = 'Đã lấy ra: %1';
							|ru = 'Отобрано: %1';
							|en = 'Picked: %1'; fa = 'Picked: %1';
							|it = 'Picked: %1';
							|pl = 'Picked: %1';
							|tr = 'Seçilen: %1'");
	Items.DecorationChoosePattern.Title = StringFunctionsClientServer.SubstituteParametersToString(FilterTemplate, Pattern);
	
	ConfigureDependentFormElements(ThisObject, "Filter");
	
EndProcedure

&AtServer
Procedure AddInstanceAtServer()
	
	InstanceId = New UUID;

	RowsToProcess = New Array;

	If Checks.Count() > 0 Then
		For Each TableRow In Checks Do
			NewRow = Object.Goods_Research.Add();
			FillPropertyValues(NewRow, TableRow);
			NewRow.Products = LastAddedItem;
			NewRow.Characteristic = LastAddedCharacteristic;
			NewRow.Series = LastAddedBatch;
			NewRow.Pattern = SampleName;
			NewRow.Count = 1;
			NewRow.InstanceId = InstanceId;
			RowsToProcess.Add(NewRow);
		EndDo;
	Else
		NewRow = Object.Goods_Research.Add();
		NewRow.Products = LastAddedItem;
		NewRow.Characteristic = LastAddedCharacteristic;
		NewRow.Series = LastAddedBatch;
		NewRow.Pattern = SampleName;
		NewRow.Count = 1;
		NewRow.InstanceId = InstanceId;
		RowsToProcess.Add(NewRow);
	EndIf;
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["Goods_Research"]);
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods_Research,
		CachedValues);
	
EndProcedure

&AtServer
Function GoodsResearchSamples()
	
	DocumentObject = FormAttributeToValue("Object");
	Return TMCommonUse.UnloadColumnValues(DocumentObject.Goods_Research, "Pattern"); 
		
EndFunction

#EndRegion

#Region OtherItems

&AtClient
Procedure NotifyAboutDocument(WriteParameters)
	
	NotificationProcessingParameter = CommonClient.CopyRecursive(WriteParameters);
	If TypeOf(FormOwner) = Type("ClientApplicationForm") Then
		IdOfOwnerSForm = FormOwner.UUID;
	Else
		IdOfOwnerSForm = Undefined;
	EndIf;
	NotificationDocumentKeys = OperationsWithDocumentJournalsClient.GetKeyParametersForDocument(
		Object.Ref, Object.Date, Undefined);
	NotificationProcessingParameter.Insert("IdOfOwnerSForm", IdOfOwnerSForm);
	NotificationProcessingParameter.Insert("NotificationDocumentKeys", NotificationDocumentKeys);
	Notify("Write_GoodsQualityResearch", NotificationProcessingParameter, Object.Ref);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	If ValueIsFilled(Object.GoodsResearchSheet) Then
		DescriptionOfGoodsResearchCard = Common.ObjectAttributeValue(Object.GoodsResearchSheet,
			"DescriptionOfUsageSpecification");
	EndIf;
	
	FillInArticleAttribute = New Structure("Products", "SKU");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.Goods_Research, StructureOfActions);
	
	StructureOfActions.Insert("FillInArticleAttribute", FillInArticleAttribute);
	
	BatchProcessingOfTablePartServer.TreatTS(Object.PlanAndResearchResult, StructureOfActions);
	
	CurParametersForSpecifyingSeries = Documents.GoodsQualityResearch.SeriesSpecificationParameters(Object);
	SeriesSpecificationParameters = New FixedStructure(CurParametersForSpecifyingSeries);
	
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["PlanAndResearchResult"]);
	ProductsServer.FillInStatusesForSpecifyingSeries(Object, SeriesSpecificationParameters["Goods_Research"]);
	
	FillInServiceDetails();
	UpdateResearchResult();
	
	// Visibility management.
	SetConditionalAppearance();
	UpdateInformationOnUseOfBatchCharacteristics();
	
EndProcedure

&AtClient
Procedure HowToCheckInstancesOnChangeCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Object.InstancesCheckMethod = ResearchMethodBeforeChange;
		Return;
	EndIf;
	
	ClearResearchResults();
	
	ResearchMethodBeforeChange = Object.InstancesCheckMethod;
	
	ConfigureDependentFormElements(ThisObject, "InstancesCheckMethod");
	
	Modified = True;

EndProcedure 

&AtServer
Procedure ClearResearchResults(UpdateTypeOfControl = False)

	Object.Goods_Research.Clear();
	If UpdateTypeOfControl Then
		Object.Control = Common.ObjectAttributeValue(Object.GoodsResearchSheet, "Control");
		Object.InstancesCheckMethod = Enums.CheckOptionsOfResearchCopies.CopyByCopy;
	EndIf;

EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	ShowAllInstances = True;
	
	TypeOfControlBeforeChange = Enums.QualityControl.Selective;
	If ValueIsFilled(Object.Control) Then
		TypeOfControlBeforeChange = Object.Control;
	EndIf;
	
	ResearchMethodBeforeChange = Enums.CheckOptionsOfResearchCopies.Overall;
	If ValueIsFilled(Object.InstancesCheckMethod) Then
		ResearchMethodBeforeChange = Object.InstancesCheckMethod;
	EndIf;
	
	If ValueIsFilled(Object.Warehouse) Then
		Items.Warehouse.ChoiceList.Clear();
		Items.Warehouse.ChoiceList.Add(Object.Warehouse);
	ElsIf ValueIsFilled(Object.RequestForControl) Then
		WarehousesList = ListOfWarehousesOfControlRequest(Object.RequestForControl);
		If WarehousesList.Count() = 1 Then
			Object.Warehouse = WarehousesList[0];
			Items.Warehouse.ChoiceList.Clear();
			Items.Warehouse.ChoiceList.Add(WarehousesList[0]);
		Else
			Items.Warehouse.ReadOnly = False;
			Items.Warehouse.ChoiceList.Clear();
			Items.Warehouse.ChoiceList.LoadValues(WarehousesList);
		EndIf;
	EndIf;
	
	ExploreMultipleGoods = Object.PlanAndResearchResult.Count() > 1;
	
	If Not ExploreMultipleGoods Then
		If Object.PlanAndResearchResult.Count() = 0 Then
			NewRow = Object.PlanAndResearchResult.Add();
			RowID = NewRow.GetID();
		Else
			RowID = Object.PlanAndResearchResult[0].GetID();
			Items.PlanAndResearchResult.CurrentRow = RowID;
		EndIf;
		Items.PlanAndResearchResult.CurrentRow = RowID;
	EndIf;
	
	If Not ValueIsFilled(Object.GoodsResearchSheet) Then
		Return;
	Else
		MapOfStudyBeforeChange = Object.GoodsResearchSheet;
	EndIf;

	Query = New Query;
	Query.Text = Catalogs.GoodsResearchSheets.QueryTextOfCheckList();

	Query.SetParameter("Ref", Object.GoodsResearchSheet);
	ValidationSample = Query.Execute().Select();
	
	While ValidationSample.Next() Do
		NewRow = Checks.Add();
		FillPropertyValues(NewRow, ValidationSample);
	EndDo;
	
	TableRow = Object.PlanAndResearchResult[0];
	LastAddedItem 	= TableRow.Products;
	LastAddedCharacteristic 	= TableRow.Characteristic;
	LastAddedBatch			= TableRow.Series;
	ItemVariantsAreUsed 			= TableRow.ItemVariantsAreUsed;
	SeriesAreUsed					= GoodsResearch.UsingSeries(TableRow.Products);
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsONChangingStudyCard()

	Query = New Query;
	Query.Text = Catalogs.GoodsResearchSheets.QueryTextOfCheckList();

	Query.SetParameter("Ref", Object.GoodsResearchSheet);
	ValidationSample = Query.Execute().Select();
	
	Checks.Clear();
	
	While ValidationSample.Next() Do
		NewRow = Checks.Add();
		FillPropertyValues(NewRow, ValidationSample);
	EndDo;
	
	DescriptionOfGoodsResearchCard = Common.ObjectAttributeValue(Object.GoodsResearchSheet,
		"DescriptionOfUsageSpecification");
	
	ClearResearchResults(True);

EndProcedure

&AtServer
Procedure FillInServiceAttributesWhenAddingGoodsResearchLineATServer(IdOfItemResearchLine)
	
	TableRow = Object.Goods_Research.FindByID(IdOfItemResearchLine);
	
	FoundInstances = Object.Goods_Research.FindRows(New Structure("Pattern", TableRow.Pattern));
	If FoundInstances.Count() = 1 Then
		TableRow.InstanceId = New UUID;
	Else
		TableRow.InstanceId = FoundInstances[0].InstanceId;
	EndIf;
	
	RowsToProcess = New Array;
	RowsToProcess.Add(TableRow);
	
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	CheckSeriesCalculateStatus = New Structure("Warehouse, SeriesSpecificationParameters", Object.Warehouse, SeriesSpecificationParameters["Goods_Research"]);
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	
	StructureOfActions = New Structure();
	StructureOfActions.Insert("FillInFeatureAttribute", FillInFeatureAttribute);
	StructureOfActions.Insert("FillInProductTypeAttribute_", FillInProductTypeAttribute_);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", CheckSeriesCalculateStatus);
	
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Goods_Research,
		CachedValues);

	Modified = True;
	
EndProcedure

&AtServer
Procedure FillInIdOfItemResearchLineATServer(IdOfItemResearchLine, Text = Undefined)
	
	TableRow = Object.Goods_Research.FindByID(IdOfItemResearchLine);
	
	If Text<>Undefined Then
		TableRow.Pattern = Text;
	EndIf;
	
	FoundInstances = Object.Goods_Research.FindRows(New Structure("Pattern", TableRow.Pattern));
	If FoundInstances.Count() = 1 Then
		TableRow.InstanceId = New UUID;
	Else
		TableRow.InstanceId = FoundInstances[0].InstanceId;
	EndIf;
		
	Modified = True;
	
EndProcedure

&AtClient
Procedure PlanAndResearchResultBeforeDeleteRowCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		PlanAndResultOfStudyBeforeDeletionAtServer();
		ConfigureDependentFormElements(ThisObject, "FormType");
	EndIf;

EndProcedure

&AtServer
Procedure SetPropsValueToAllLines(Var_AttributeName, ValueToSet, SelectedRows)

	If TypeOf(SelectedRows) = Type("Array") Then
		ArrayOfIdentifiers = SelectedRows;
	Else
		ArrayOfIdentifiers = CommonClientServer.ValueInArray(SelectedRows);
	EndIf;

	For Each RowID In ArrayOfIdentifiers Do
		If RowID <> Undefined Then
			Data = Object.Goods_Research.FindByID(RowID);
			Data[Var_AttributeName] = ValueToSet;
		EndIf;
	EndDo;

EndProcedure

&AtServer
Function StudyIsCompleted(Filter)
	
	DocumentObject = FormAttributeToValue("Object");
	
	FoundStudies = DocumentObject.Goods_Research.FindRows(Filter);
	If FoundStudies.Count() = 0 Then
		Return False;
	EndIf;
	
	StudyIsCompleted = True;
	
	For Each ArrayRow In FoundStudies Do
		If Not ValueIsFilled(ArrayRow.Result) Then
			StudyIsCompleted = False;
			Break;
		EndIf;
	EndDo;
	
	Return StudyIsCompleted;
	
EndFunction

&AtServer
Procedure PlanAndResultOfStudyBeforeDeletionAtServer()
	
	For Each CurID_ In Items.PlanAndResearchResult.SelectedRows Do
		DeleteStudies(CurID_);
		Object.PlanAndResearchResult.Delete(Object.PlanAndResearchResult.FindByID(CurID_));
	EndDo;
	
	If Not ExploreMultipleGoods Then
		If Object.PlanAndResearchResult.Count() = 0 Then
			NewRow = Object.PlanAndResearchResult.Add();
			RowID = NewRow.GetID();
		Else
			RowID = Object.PlanAndResearchResult[0].GetID();
			Items.PlanAndResearchResult.CurrentRow = RowID;
		EndIf;
		Items.PlanAndResearchResult.CurrentRow = RowID;
	EndIf;
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure DeleteStudies(CurrentID)
	
	CurrentData = Object.PlanAndResearchResult.FindByID(CurrentID);
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("Products", CurrentData.Products);
	Filter.Insert("Characteristic", CurrentData.Characteristic);
	Filter.Insert("Series", CurrentData.Series);
	FoundRows = Object.PlanAndResearchResult.FindRows(Filter);
	If FoundRows.Count() = 1 Then
		FoundStudies = Object.Goods_Research.FindRows(New Structure("Products, Characteristic, Series", CurrentData.Products, CurrentData.Characteristic, CurrentData.Series));
		If FoundStudies.Count() <> 0 Then
			For Each String In FoundStudies Do
				Object.Goods_Research.Delete(String);
			EndDo;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetResultOfStudyForLine()

	CurrentData = Items.Goods_Research.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;

	If CurrentData.Damaged Then
		Return;
	EndIf;

	ClearMessages();

	MessageTemplate = NStr("vi = 'Cột ""%1"" tại dòng %2 của phần bảng ""%3"" được điền không chính xác. %4';
							|ru = 'Не верно заполнена колонка ""%1"" в строке %2 табличной части ""%3"". %4';
							|en = 'The ""%1"" column in line %2 of the ""%3"" table is not filled in correctly. %4'; fa = 'The ""%1"" column in line %2 of the ""%3"" table is not filled in correctly. %4';
							|it = 'The ""%1"" column in line %2 of the ""%3"" table is not filled in correctly. %4';
							|pl = 'The ""%1"" column in line %2 of the ""%3"" table is not filled in correctly. %4';
							|tr = '""%3"" tablo bölümü %2 satırında ""%1"" sütunu yanlış doldurulmuş. %4'");
	NormField = NStr("vi = 'Định mức';
					|ru = 'Норма';
					|en = 'Standard'; fa = 'استاندارد';
					|it = 'Standard';
					|pl = 'Standard';
					|tr = 'Norm'");
	Real = TrimAll(CurrentData.Real);
	Norm = TrimAll(CurrentData.Norm);
	MessageText = "";

	HasError = False;
	ThereIsMistakeFact = False;
	CheckRange = False;
	CheckListOfValues = False;
		
		// Fact Checking
	ValueActual = StringFunctionsClientServer.StringToNumber(Real);
	If ValueActual = Undefined Then
		HasError = True;
		ThereIsMistakeFact = True;
		CheckListOfValues = True;
	EndIf;
		
		// Numeric value
	NormNumber = StringFunctionsClientServer.StringToNumber(Norm);
	If NormNumber = Undefined Then
		HasError = True;
		CheckRange = True;
	EndIf;

	If Not HasError Then
		If ValueActual = NormNumber Then
			CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.IsPassed");
		Else
			CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.NotPassed");
		EndIf;
		Return;
	EndIf;
		
		// Span
	PartsOfRange = StrSplit(Norm, "-");
	If PartsOfRange.Count() = 2 And CheckRange And Not ThereIsMistakeFact Then

		HasError = False;

		NumberOnLeft = StringFunctionsClientServer.StringToNumber(PartsOfRange[0]);
		If NumberOnLeft = Undefined Then
			HasError = True;
		EndIf;

		NumberOnRight = StringFunctionsClientServer.StringToNumber(PartsOfRange[1]);
		If NumberOnRight = Undefined Then
			HasError = True;
		EndIf;

		If Not HasError Then
			If NumberOnLeft > NumberOnRight Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Định mức';
																|ru = 'Норма';
																|en = 'Standard'; fa = 'استاندارد';
																|it = 'Standard';
																|pl = 'Standard';
																|tr = 'Norm'"), CurrentData.LineNumber, NStr(
						"vi = 'Nghiên cứu';
						|ru = 'Исследования';
						|en = 'Research'; fa = 'تحقیق';
						|it = 'Research';
						|pl = 'Research';
						|tr = 'İncelemeler'"), NStr("vi = 'Số ở phần đầu của khoảng lớn hơn số ở phần thứ hai';
												|ru = 'В первой части диапазона число больше чем во второй';
												|en = 'The number in the first part of the range is greater than in the second part'; fa = 'The number in the first part of the range is greater than in the second part';
												|it = 'The number in the first part of the range is greater than in the second part';
												|pl = 'The number in the first part of the range is greater than in the second part';
												|tr = 'Aralığın ilk kısmındaki sayı ikinciden büyük'"));

				CommonClient.MessageToUser(
					MessageText, , NormField, "Object.Norm", True);
				HasError = True;
			EndIf;
		EndIf;

		If Not HasError Then
			If ValueActual >= NumberOnLeft And ValueActual <= NumberOnRight Then
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.IsPassed");
			Else
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.NotPassed");
			EndIf;
		Else
			CheckListOfValues = True;
		EndIf;
	ElsIf PartsOfRange.Count() = 3 And CheckRange And Not ThereIsMistakeFact Then
		HasError = False;

		ValueOfD1 = TrimAll(PartsOfRange[0]);
		NumberOnLeft = StringFunctionsClientServer.StringToNumber(PartsOfRange[1]);
		If NumberOnLeft = Undefined Or Not IsBlankString(ValueOfD1) Then

			If Not IsBlankString(ValueOfD1) Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Định mức';
																|ru = 'Норма';
																|en = 'Standard'; fa = 'استاندارد';
																|it = 'Standard';
																|pl = 'Standard';
																|tr = 'Norm'"), CurrentData.LineNumber, NStr(
						"vi = 'Nghiên cứu';
						|ru = 'Исследования';
						|en = 'Research'; fa = 'تحقیق';
						|it = 'Research';
						|pl = 'Research';
						|tr = 'İncelemeler'"), NStr("vi = 'Số ở phần đầu của khoảng lớn hơn số ở phần thứ hai';
												|ru = 'В первой части диапазона число больше чем во второй';
												|en = 'The number in the first part of the range is greater than in the second part'; fa = 'The number in the first part of the range is greater than in the second part';
												|it = 'The number in the first part of the range is greater than in the second part';
												|pl = 'The number in the first part of the range is greater than in the second part';
												|tr = 'Aralığın ilk kısmındaki sayı ikinciden büyük'"));
			EndIf;

			CommonClient.MessageToUser(MessageText, , NormField, "Object.Norm", True);
			HasError = True;
		EndIf;
		NumberOnRight = StringFunctionsClientServer.StringToNumber(PartsOfRange[2]);
		If NumberOnRight = Undefined Then
			HasError = True;
		EndIf;

		If Not HasError Then
			If -NumberOnLeft > NumberOnRight Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Định mức';
																|ru = 'Норма';
																|en = 'Standard'; fa = 'استاندارد';
																|it = 'Standard';
																|pl = 'Standard';
																|tr = 'Norm'"), CurrentData.LineNumber, NStr(
						"vi = 'Nghiên cứu';
						|ru = 'Исследования';
						|en = 'Research'; fa = 'تحقیق';
						|it = 'Research';
						|pl = 'Research';
						|tr = 'İncelemeler'"), NStr("vi = 'Số ở phần đầu của khoảng lớn hơn số ở phần thứ hai';
												|ru = 'В первой части диапазона число больше чем во второй';
												|en = 'The number in the first part of the range is greater than in the second part'; fa = 'The number in the first part of the range is greater than in the second part';
												|it = 'The number in the first part of the range is greater than in the second part';
												|pl = 'The number in the first part of the range is greater than in the second part';
												|tr = 'Aralığın ilk kısmındaki sayı ikinciden büyük'"));

				CommonClient.MessageToUser(MessageText, , NormField, "Object.Norm", True);
				HasError = True;
			EndIf;
		EndIf;

		If Not HasError Then
			If ValueActual >= -NumberOnLeft And ValueActual <= NumberOnRight Then
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.IsPassed");
			Else
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.NotPassed");
			EndIf;
		Else
			CheckListOfValues = True;
		EndIf;

	ElsIf PartsOfRange.Count() = 4 And CheckRange And Not ThereIsMistakeFact Then

		HasError = False;

		ValueOfD1 = TrimAll(PartsOfRange[0]);
		NumberOnLeft = StringFunctionsClientServer.StringToNumber(PartsOfRange[1]);
		If NumberOnLeft = Undefined Or Not IsBlankString(ValueOfD1) Then
			HasError = True;
		EndIf;

		ValueOfD3 = TrimAll(PartsOfRange[2]);
		NumberOnRight = StringFunctionsClientServer.StringToNumber(PartsOfRange[3]);
		If NumberOnRight = Undefined Or Not IsBlankString(ValueOfD3) Then
			HasError = True;
		EndIf;

		If Not HasError Then
			If -NumberOnLeft > -NumberOnRight Then
				MessageText = StrTemplate(MessageTemplate, NStr("vi = 'Định mức';
																|ru = 'Норма';
																|en = 'Standard'; fa = 'استاندارد';
																|it = 'Standard';
																|pl = 'Standard';
																|tr = 'Norm'"), CurrentData.LineNumber, NStr(
						"vi = 'Nghiên cứu';
						|ru = 'Исследования';
						|en = 'Research'; fa = 'تحقیق';
						|it = 'Research';
						|pl = 'Research';
						|tr = 'İncelemeler'"), NStr("vi = 'Số ở phần đầu của khoảng lớn hơn số ở phần thứ hai';
												|ru = 'В первой части диапазона число больше чем во второй';
												|en = 'The number in the first part of the range is greater than in the second part'; fa = 'The number in the first part of the range is greater than in the second part';
												|it = 'The number in the first part of the range is greater than in the second part';
												|pl = 'The number in the first part of the range is greater than in the second part';
												|tr = 'Aralığın ilk kısmındaki sayı ikinciden büyük'"));

				CommonClient.MessageToUser(MessageText, , NormField, "Object.Norm", True);
				HasError = True;
			EndIf;
		EndIf;

		If Not HasError Then
			If ValueActual >= -NumberOnLeft And ValueActual <= -NumberOnRight Then
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.IsPassed");
			Else
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.NotPassed");
			EndIf;
		Else
			CheckListOfValues = True;
		EndIf;
	EndIf;

		// List of values
	If CheckListOfValues And (StrFind(Norm, ";") > 0 Or StrFind(Norm, "/") > 0) Then
		ValueList = StrSplit(Norm, ";/");
		CurrentData.Result = PredefinedValue(
				"Enum.GoodsResearchResult.NotPassed");
		For Each Value In ValueList Do
			If Value = Real Then
				CurrentData.Result = PredefinedValue(
						"Enum.GoodsResearchResult.IsPassed");
				Break;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

&AtServer
Procedure InitializeCache()
	
	Cache = New Structure;
	
	Cache.Insert("ColorOfClickedHyperlink", StyleColors.HyperlinkColor);
	Cache.Insert("ColorOfNonClickedHyperlink", StyleColors.UnavailableTextColor);
	
EndProcedure

&AtClient
Procedure FillOutApplicationForQualityControlOfItemsEnd(RequestForGoodsQualityControl, AdditionalParameters) Export

	If RequestForGoodsQualityControl = Undefined Then
		Return;
	EndIf;

	FillOutApplicationForQualityControlOfItemsATServer(RequestForGoodsQualityControl);

EndProcedure

&AtServer
Procedure FillOutApplicationForQualityControlOfItemsATServer(RequestForGoodsQualityControl)
	
	WarehouseControlRequests = Common.ObjectAttributeValue(RequestForGoodsQualityControl, "Warehouse");

	If ValueIsFilled(WarehouseControlRequests) Then
		Object.Warehouse = WarehouseControlRequests;
		Items.Warehouse.ChoiceList.Clear();
		Items.Warehouse.ChoiceList.Add(WarehouseControlRequests);
	Else
		WarehousesList = ListOfWarehousesOfControlRequest(RequestForGoodsQualityControl);
		If WarehousesList.Count() = 1 Then
			Object.Warehouse = WarehousesList[0];
			Items.Warehouse.ChoiceList.Clear();
			Items.Warehouse.ChoiceList.Add(WarehousesList[0]);
		Else
			Items.Warehouse.ReadOnly = False;
			Items.Warehouse.ChoiceList.Clear();
			Items.Warehouse.ChoiceList.LoadValues(WarehousesList);
		EndIf;
	EndIf;
	Object.RequestForControl = RequestForGoodsQualityControl;
	Items.Basis.Title = Common.SubjectString(Object.RequestForControl);

	Modified = True;
	
EndProcedure

&AtServer
Function ListOfWarehousesOfControlRequest(RequestForGoodsQualityControl)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	RequestForGoodsQualityControlGoods.Warehouse AS Warehouse
		|FROM
		|	Document.RequestForGoodsQualityControl.Goods AS RequestForGoodsQualityControlGoods
		|WHERE
		|	RequestForGoodsQualityControlGoods.Ref = &Ref
		|GROUP BY
		|	RequestForGoodsQualityControlGoods.Warehouse";
	
	Query.SetParameter("Ref", RequestForGoodsQualityControl);
	
	QueryResult = Query.Execute().Unload().UnloadColumn("Warehouse");
		
	Return QueryResult;
	
EndFunction

&AtServer
Function ItemUsedIsPlanAndResultOfStudy()
	
	DocumentObject = FormAttributeToValue("Object");
	ItemList = TMCommonUse.UnloadColumnValues(DocumentObject.PlanAndResearchResult, "Products");
	CommonClientServer.DeleteAllValueOccurrencesFromArray(ItemList, Catalogs.Products.EmptyRef());
	Return ItemList;
		
EndFunction

&AtServer
Function ItemUsedCharacteristicsBatchPlanAndResultOfStudy()
	
	DocumentObject = FormAttributeToValue("Object");
	LinesOfResearchPlan = DocumentObject.PlanAndResearchResult.Unload(, "Products, Characteristic, Series, RowID");
	LinesOfResearchPlan = CollapseLeavingFirstId(LinesOfResearchPlan);
	ItemList= New Array;
	For Each TSRow In LinesOfResearchPlan Do
		If ValueIsFilled(TSRow.Products) Then
			NewItem = New Structure;
			NewItem.Insert("Products", TSRow.Products);
			NewItem.Insert("Characteristic", TSRow.Characteristic);
			NewItem.Insert("Series", TSRow.Series);
			NewItem.Insert("RowID", TSRow.RowID);
			ItemList.Add(NewItem);
		EndIf;
	EndDo;
	
	Return ItemList;
		
EndFunction

&AtServer
Function CollapseLeavingFirstId(Val ItemList)
	
	UniquePlan = ItemList.CopyColumns();
	
	For Each TSRow In ItemList Do
		FoundRecord = False;
		
		For Each UniqueString In UniquePlan Do
			If TSRow.Products = UniqueString.Products
				And TSRow.Characteristic = UniqueString.Characteristic
				And TSRow.Series = UniqueString.Series Then
					FoundRecord = True;
					Break;
			EndIf;
		EndDo;
	
		If Not FoundRecord Then
			NewRow = UniquePlan.Add();
			FillPropertyValues(NewRow, TSRow);
		EndIf;
		
	EndDo;
	
	Return UniquePlan;
		
EndFunction

&AtServer
Function CharacteristicsUsedArePlanAndResultOfStudy(Products)
	
	DocumentObject = FormAttributeToValue("Object");
	FoundRows = DocumentObject.PlanAndResearchResult.Unload(New Structure("Products", Products));
	ListOfCharacteristics = New Array;
	For Each String In FoundRows Do
		If ValueIsFilled(String.Characteristic) Then
			ListOfCharacteristics.Add(String.Characteristic);
		EndIf;
	EndDo;
	
	Return CommonClientServer.CollapseArray(ListOfCharacteristics);
		
EndFunction

&AtServer
Function CharacteristicsOfItemUsedArePlanAndResultOfStudy()
	
	DocumentObject = FormAttributeToValue("Object");
	ItemsCharacteristics = DocumentObject.PlanAndResearchResult.Unload(, "Products, Characteristic");
	ItemsCharacteristics.GroupBy("Products, Characteristic");
	ListOfCharacteristics = New Array;
	For Each TSRow In ItemsCharacteristics Do
		NewItem = New Structure;
		NewItem.Insert("Products", TSRow.Products);
		NewItem.Insert("Characteristic", TSRow.Characteristic);
		ListOfCharacteristics.Add(NewItem);
	EndDo;
	
	Return ListOfCharacteristics;
		
EndFunction

#EndRegion

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
