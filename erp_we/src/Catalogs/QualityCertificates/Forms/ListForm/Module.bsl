
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	TypesArray = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	Items.CertificateType.ChoiceList.LoadValues(TypesArray);
	
	CommonClientServer.SetDynamicListFilterItem(
		Scope,
		"QualityCertificate",
		Catalogs.QualityCertificates.EmptyRef(),
		DataCompositionComparisonType.Equal);
	
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"ProductKind",
		ProductKindSelection,
		ValueIsFilled(ProductKindSelection));
	
	UsingSelection = ValueIsFilled(NomenclatureSelection)
							Or ValueIsFilled(ProductKindSelection);
	
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"Products",
		NomenclatureSelection,
		UsingSelection);
	
	If OnlyValidAsOfTheDate Then
		Items.Date.Enabled = True;
	Else
		Items.Date.Enabled = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.QualityCertificates) Then
		Items.GroupCommandBarSetStatus.Enabled = False;
	EndIf;
	
	Date = CurrentSessionDate();
	
	ProductsLocalization.WhenCreatingOnServer_NomenclatureCertificates_ListForm(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.CommandBarProductCertificates;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	TMCommonUseClientServer.SetFormItemProperty(Items, "ItemCertificatesChange",
		"Visible", AccessRight("Update", Metadata.Catalogs.QualityCertificates));
	
	Items.CertificatesOfTheItemItemsWithExpiringCertificates.Visible = AccessRight("Use",
																							Metadata.Reports.GoodsWithExpiringCertificates);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject,
		Items.CommandBarProductCertificates);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_QualityCertificate" Then
		
		TypesOfCertificates = CreateListToSelectCertificateTypes();
		
		Items.CertificateType.ChoiceList.LoadValues(TypesOfCertificates);
		Items.QualityCertificates.Refresh();
		
		If Not Items.ScopeGroup.Hidden() Then
			Items.Scope.Refresh();
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductKindSelectionOnChange(Item)
		
	If ValueIsFilled(NomenclatureSelection) Then
		If ProductKindSelection <> ProductKind(NomenclatureSelection) Then
			NomenclatureSelection = PredefinedValue("Catalog.Products.EmptyRef");
		EndIf;
	EndIf;
	
	SetSelectionsWhenChangingProducts();
	
EndProcedure

&AtClient
Procedure NomenclatureSelectionOnChange(Item)
	
	SetSelectionsWhenChangingProducts();
	
EndProcedure

&AtClient
Procedure CertificateTypeOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		QualityCertificates,
		"CertificateType",
		CertificateType,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(CertificateType));
	
EndProcedure

&AtClient
Procedure CertificateTypeAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	TypesArray = GenerateListOfTypes(Text);
	
	ChoiceData = New ValueList;
	ChoiceData.LoadValues(TypesArray);

EndProcedure

&AtClient
Procedure OnlyValidAsOfTheDateOnChange(Item)
	
	If OnlyValidAsOfTheDate Then
		Items.Date.Enabled = True;
	Else
		Items.Date.Enabled = False;
	EndIf;
	
	SetSelectionForOnlyThoseValidOnDate();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetSelectionForOnlyThoseValidOnDate();
	
EndProcedure

&AtClient
Procedure WhenChangingAttributesOfForm(Item)
	
	ProductsClientLocalization.WhenChangingDetails_CertificatesOfItem_FormOfList(Item, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQualityCertificates

&AtClient
Procedure QualityCertificatesOnActivateRow(Item)
	
	AttachIdleHandler("ProductCertificatesActivatingLine", 0.1, True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure QualityCertificatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Var_Group Then
		Return;
	EndIf;
	
	Cancel = True;
	
	FormParameters = New Structure;
	
	If Copy Then
		If Items.QualityCertificates.CurrentData = Undefined Then
			Return;
		ElsIf Items.QualityCertificates.CurrentData.IsFolder Then
			Return;
		EndIf;
		
		FormParameters.Insert("CopyingValue", Items.QualityCertificates.CurrentData.Ref);
	Else
		FormParameters.Insert("Products",		NomenclatureSelection);
		FormParameters.Insert("CertificateType",	CertificateType);
		FormParameters.Insert("ProductKind",	ProductKindSelection);
	EndIf;
	
	OpenForm("Catalog.QualityCertificates.Form.ItemForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure QualityCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	If ProductsClientLocalization.ChoosingStatusOfRosaccreditation(Field, Items) Then
		ProductsClientLocalization.WhenChoosingStatusOfRosaccreditation(Item, StandardProcessing);
	Else
		TMCommonUseClient.ChangeElement(Item);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScope

&AtClient
Procedure ScopeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetCurrentStatus(Command)
	
	ProductsClient.SetStatusOfNomenclatureCertificates(
		ThisObject,
		Items.QualityCertificates,
		PredefinedValue("Enum.StatusesOfQualityCertificates.Valid_"));
	
EndProcedure

&AtClient
Procedure SetStatusNotValid(Command)
	
	ProductsClient.SetStatusOfNomenclatureCertificates(
		ThisObject,
		Items.QualityCertificates,
		PredefinedValue("Enum.StatusesOfQualityCertificates.Inactive"));
	
EndProcedure

&AtClient
Procedure OpenImage(Command)
	
	ClearMessages();
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If CurrentRow.IsFolder Then
		MessageText = NStr("vi = 'Đối với nhóm ""%1"" không cần tiến hành ghi nhận hình ảnh của chứng nhận';
							|ru = 'Для группы ""%1"" не требуется ведение учета изображений сертификатов';
							|en = 'There is no need to keep records of certificate images for the %1 group'; fa = 'There is no need to keep records of certificate images for the %1 group';
							|it = 'There is no need to keep records of certificate images for the %1 group';
							|pl = 'There is no need to keep records of certificate images for the %1 group';
							|tr = '""%1"" grubu için sertifika resimlerinin muhasebesini tutmak gerekli değildir'");
		MessageText = StrTemplate(MessageText, String(CurrentRow.Ref));
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
	EndIf;
	
	ReturnStructure = OpenImageOnServer(CurrentRow.Ref);
	
	If ReturnStructure.Result = "NoImages" Then
		MessageText = NStr("vi = 'Đối với chứng nhận hàng hóa ""%Certificate%"" không có hình ảnh để xem trước';
							|ru = 'Для сертификата номенклатуры ""%Certificate%"" отсутствует изображение для просмотра';
							|en = 'There is no image for quality certificate ""%Certificate%""'; fa = 'There is no image for quality certificate ""%Certificate%""';
							|it = 'Per il certificato di articolo""%Certificate%"" manca l''immagine per la visualizzazione';
							|pl = 'Dla certyfikatu ""%Certificate%"" brak obrazu do przeglądania';
							|tr = 'Kalite belgesi için ""%Certificate%"" önizleme görüntüsü yok'");
		MessageText = StrReplace(MessageText, "%Certificate%", CurrentRow.Ref);
		
		CommonClient.MessageToUser(MessageText);
	ElsIf ReturnStructure.Result = "OneImage" Then
		FilesOperationsClient.OpenFile(
			FilesOperationsInternalServerCall.GetFileData(
			ReturnStructure.AttachedFile,
			UUID));
	Else
		ChoiceParameters		= New Structure("FileOwner, CloseOnChoice, ChoiceMode",
												CurrentRow.Ref, True, True);
		CallbackDescription	= New CallbackDescription("OpenImageCompletion", ThisObject);
		
		OpenForm("DataProcessor.FilesOperations.Form.AttachedFiles",
					ChoiceParameters,
					,
					,
					,
					,
					CallbackDescription,
					FormWindowOpeningMode.LockOwnerWindow);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoodsWithExpiringCertificates(Command)
	
	Form = GetForm("Report.GoodsWithExpiringCertificates.Form");
	
	DataCompositionSettingsComposer = Form.Report.SettingsComposer;
	UserSettings = DataCompositionSettingsComposer.UserSettings;
	
	If ValueIsFilled(ProductKindSelection) Then
		ValueList = New ValueList;
		ValueList.Add(ProductKindSelection);

		SetCustomSetting(DataCompositionSettingsComposer,
			UserSettings,
			"ProductKind",
			ValueList,
			DataCompositionComparisonType.InList);
	Else
		ClearUserSetting(DataCompositionSettingsComposer,
											UserSettings,
											"ProductKind");
	EndIf;
	
	If ValueIsFilled(NomenclatureSelection) Then
		ValueList = New ValueList;
		ValueList.Add(NomenclatureSelection);
		
		SetCustomSetting(DataCompositionSettingsComposer, 
			UserSettings,
			"Products",
			ValueList,
			DataCompositionComparisonType.InList);
	Else
		ClearUserSetting(DataCompositionSettingsComposer,
											UserSettings,
											"Products");
	EndIf;
	
	If ValueIsFilled(CertificateType) Then
		SetCustomSetting(DataCompositionSettingsComposer,
			UserSettings,
			"CertificateType",
			CertificateType,
			DataCompositionComparisonType.Equal);
	Else
		ClearUserSetting(DataCompositionSettingsComposer,
											UserSettings,
											"CertificateType");
	EndIf;
	
	If ValueIsFilled(Date) And OnlyValidAsOfTheDate Then
		Parameter = New Structure();
		Parameter.Insert("Value",		Date);
		Parameter.Insert("Use",	True);
		
		SetCustomSettingParameter(UserSettings, "InvalidAsOfTheDate", Parameter);
	EndIf;
	
	FormParameters = New Structure("GenerateOnOpen, UserSettings",
									True, UserSettings);
	
	OpenForm("Report.GoodsWithExpiringCertificates.Form", FormParameters);
	
EndProcedure

&AtClient
Procedure ExecuteFormCommand(Command)
	
	ProductsClientLocalization.ExecuteCommand_NomenclatureCertificates_ListForm(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.QualityCertificates);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeProducts.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Products");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với toàn bộ mặt hàng>';
													|ru = '<для всей номенклатуры>';
													|en = '<for all items>'; fa = '<برای همه اقلام>';
													|it = '<comune per tutti articoli>';
													|pl = '<dla całej nomenklatury>';
													|tr = '<tüm öğeler için>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeCharacteristic.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.UseCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả đặc tính>';
													|ru = '<для всех характеристик>';
													|en = '<for all variants>'; fa = '<برای همه گونه‌ها>';
													|it = '<comune per tutte le caratteristiche>';
													|pl = '<dla wszystkich charakterystyk>';
													|tr = '<tüm varyantlar için>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeSeries.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.KeepAccountingByBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả sê-ri>';
													|ru = '<для всех серий>';
													|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
													|it = '<comune per tutte le serie>';
													|pl = '<dla wszystkich serii>';
													|tr = '<tüm partiler için>'"));
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject,
																			"ScopeCharacteristic",
																			"Scope.UseCharacteristics");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ScopeSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Scope.KeepAccountingByBatch");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<chưa chỉ ra sê-ri>';
													|ru = '<серия не указывается>';
													|en = '<batch is not specified>'; fa = '<بچ مشخص نشده است>';
													|it = '<serie non è indicata>';
													|pl = '<seria nie jest określana>';
													|tr = '<parti belirtilmemektedir>'"));
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.QualityCertificatesValidTo.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("QualityCertificates.Permanent");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочный>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<indeterminato>';
													|pl = '<bezterminowe>';
													|tr = '<süresiz>'"));
	
	//
	ProductsLocalization.SetConditionalAppearanceOfListOfCertificatesOfNomenclature(ThisObject);
	
EndProcedure

&AtServerNoContext
Function CreateListToSelectCertificateTypes()
	
	Return Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	
EndFunction

&AtServer
Function ProductKind(Products)
	
	Return Common.ObjectAttributeValue(Products, "ProductKind");
	
EndFunction

&AtClient
Procedure SetSelectionsWhenChangingProducts()
	
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"Products",
		NomenclatureSelection,
		ValueIsFilled(NomenclatureSelection));
	
	If ValueIsFilled(NomenclatureSelection) Then
		
		ProductKindSelection = ProductKind(NomenclatureSelection);
		
		CommonClientServer.SetDynamicListParameter(
			QualityCertificates,
			"ProductKind",
			ProductKindSelection,
			ValueIsFilled(ProductKindSelection));
		
		CommonClientServer.SetDynamicListParameter(
			QualityCertificates,
			"ItemTypeOnly",
			ProductKindSelection,
			False);
		
		If Not ValueIsFilled(TableDisplayOption) Then
			If Items.QualityCertificates.Representation = TableRepresentation.HierarchicalList Then
				TableDisplayOption = "HierarchicalList";
			Else
				TableDisplayOption = Items.QualityCertificates.Representation;
			EndIf;
			Items.QualityCertificates.Representation = TableRepresentation.List;
		EndIf;
		
	Else
		
		CommonClientServer.SetDynamicListParameter(
			QualityCertificates,
			"ItemTypeOnly",
			ProductKindSelection,
			ValueIsFilled(ProductKindSelection));
		
		CommonClientServer.SetDynamicListParameter(
			QualityCertificates,
			"ProductKind",
			ProductKindSelection,
			False);
		
		If ValueIsFilled(TableDisplayOption) Then
			If TableDisplayOption = "HierarchicalList" Then
				Items.QualityCertificates.Representation = TableRepresentation.HierarchicalList;
			Else
				Items.QualityCertificates.Representation = TableRepresentation[TableDisplayOption];
			EndIf;
			TableDisplayOption = Undefined;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function GenerateListOfTypes(Text)
	
	Return Catalogs.QualityCertificates.AutomaticSelectionOfCertificateTypes(Text);
	
EndFunction

&AtClient
Procedure SetSelectionForOnlyThoseValidOnDate()
	
	UsingSelection = OnlyValidAsOfTheDate
							And ValueIsFilled(Date);
	
	GroupOperatesUnder = CommonClientServer.CreateFilterItemGroup(
										TMCommonUseClientServer.GetDynamicListSelection(QualityCertificates).Items,
										"GroupOperatesUnder",
										DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.SetFilterItem(GroupOperatesUnder,
														"Status",
														PredefinedValue("Enum.StatusesOfQualityCertificates.Valid_"),
														DataCompositionComparisonType.Equal,
														"PickingByStatuses",
														UsingSelection);
	
	GroupSelectionByDate = CommonClientServer.CreateFilterItemGroup(
							GroupOperatesUnder,
							"GroupSelectionByDate",
							DataCompositionFilterItemsGroupType.OrGroup);
	
	GroupSelectionByExpirationDate = CommonClientServer.CreateFilterItemGroup(
									GroupSelectionByDate,
									"GroupSelectionByExpirationDate",
									DataCompositionFilterItemsGroupType.AndGroup);
	
	CommonClientServer.SetFilterItem(GroupSelectionByExpirationDate,
														"StartDateOfValidityPeriod",
														Date,
														DataCompositionComparisonType.LessOrEqual,
														"SelectionByStartDateOfValidityPeriod",
														UsingSelection);
	
	CommonClientServer.SetFilterItem(GroupSelectionByExpirationDate,
														"ValidTo",
														Date,
														DataCompositionComparisonType.GreaterOrEqual,
														"SelectionByExpirationDate",
														UsingSelection);
	
	CommonClientServer.SetFilterItem(GroupSelectionByDate,
														"Permanent",
														True,
														DataCompositionComparisonType.Equal,
														"SelectionByDateIsIndefinite",
														UsingSelection);
	
EndProcedure

&AtClient
Procedure ProductCertificatesActivatingLine()
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	
	If CurrentRow <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(
			Scope,
			"QualityCertificate",
			CurrentRow.Ref,
			DataCompositionComparisonType.Equal);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			Scope,
			"QualityCertificate",
			PredefinedValue("Catalog.QualityCertificates.EmptyRef"),
			DataCompositionComparisonType.Equal);
	EndIf;

EndProcedure

&AtClient
Procedure OpenImageCompletion(Result, AdditionalParameters) Export
	
	SelectionValue = Result;
	
	If ValueIsFilled(SelectionValue) Then
		FilesOperationsClient.OpenFile(
			FilesOperationsInternalServerCall.GetFileData(
			SelectionValue,
			UUID));
	EndIf;
	
EndProcedure

&AtServer
Function OpenImageOnServer(QualityCertificate);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(Files.Ref)				AS AttachedFile,
	|	COUNT(DISTINCT Files.Ref)	AS FilesCount,
	|	Files.FileOwner					AS FileOwner
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS Files
	|WHERE
	|	Files.FileOwner = &FileOwner
	|	AND Files.DeletionMark = FALSE
	|
	|GROUP BY
	|	Files.FileOwner";
	
	Query.SetParameter("FileOwner", QualityCertificate);
	
	Selection = Query.Execute().Select();
	ReturnStructure = New Structure;
	
	If Selection.Next() Then
		If Selection.FilesCount > 1 Then
			ReturnStructure.Insert("Result", "ArrayOfImages");
		ElsIf Selection.FilesCount = 1 Then
			ReturnStructure.Insert("Result",				"OneImage");
			ReturnStructure.Insert("AttachedFile",	Selection.AttachedFile);
		EndIf;
	Else
		ReturnStructure.Insert("Result", "NoImages");
	EndIf;
	
	Return ReturnStructure;
	
EndFunction

// Parameters:
//	DataCompositionSettingsComposer - DataCompositionSettingsComposer - 
//	UserSettings - DataCompositionUserSettings - 
//	SettingName - String - 
//	SettingValue - String, ValueList of Arbitrary - 
//	Var_ComparisonType - DataCompositionComparisonType - 
//
&AtClient
Procedure SetCustomSetting(DataCompositionSettingsComposer,
												UserSettings,
												SettingName,
												SettingValue,
												Var_ComparisonType)
	
	LayoutField	= New DataCompositionField(SettingName);
	FilterElement	= Undefined;
	
	For Each Item In DataCompositionSettingsComposer.Settings.Filter.Items Do
		If Item.LeftValue = LayoutField Then
			FilterElement = Item;
			
			Break;
		EndIf;
	EndDo;
	
	If FilterElement = Undefined Then
		Return;
	EndIf;
	
	Item = UserSettings.Items.Find(FilterElement.UserSettingID);
	Item.ComparisonType	= Var_ComparisonType;
	Item.RightValue	= SettingValue;
	Item.Use	= True;
	
EndProcedure	

// Parameters:
//	UserSettings - DataCompositionUserSettings - 
//	SettingName - String - 
//	Parameter - Structure - Contains:
//	* Use - Boolean -
//	* Value - Date -
//
&AtClient
Procedure SetCustomSettingParameter(UserSettings, SettingName, Parameter)
	
	LayoutFieldParameter = New DataCompositionParameter(SettingName);
	
	For Each Item In UserSettings.Items Do
		If Item.Parameter = LayoutFieldParameter Then
			Item.Value = Parameter.Value;
			Item.Use = Parameter.Use;
			
			Break;
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
// 	DataCompositionSettingsComposer - DataCompositionSettingsComposer - 
// 	UserSettings - DataCompositionUserSettings - 
// 	SettingName - String - LongDesc
&AtClient
Procedure ClearUserSetting(DataCompositionSettingsComposer, UserSettings, SettingName)
	
	LayoutField = New DataCompositionField(SettingName);
	FilterElement = Undefined;
	
	For Each Item In DataCompositionSettingsComposer.Settings.Filter.Items Do
		If Item.LeftValue = LayoutField Then
			FilterElement = Item;
			
			Break;
		EndIf;
	EndDo;
	
	If FilterElement = Undefined Then
		Return;
	EndIf;
	
	Item = UserSettings.Items.Find(FilterElement.UserSettingID);
	
	If Item = Undefined Then
		Return;
	EndIf;
	
	Item.Use = False
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.QualityCertificates);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.QualityCertificates, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.QualityCertificates);
EndProcedure
// End StandardSubsystems.AttachableCommands

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
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
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
