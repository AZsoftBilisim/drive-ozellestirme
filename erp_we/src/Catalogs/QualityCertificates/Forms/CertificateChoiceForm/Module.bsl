#Region Variables

&AtClient
Var ClosingInProgress;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	FOUseProductCharacteristics = GetFunctionalOption("UseItemVariants");
	FOUseSeriesProducts = GetFunctionalOption("UseItemsBatch");
	
	Parameters.Property("Products",OriginalProducts); 
	ProductAttributes = Common.ObjectAttributesValues(OriginalProducts,"ProductKind, UseVariants");
	OriginalProductKind = ProductAttributes.ProductKind;	
	TypeOfProductsUseSeries = Common.ObjectAttributeValue(OriginalProductKind,"KeepAccountingByBatch");
	NotUseCharacteristics =  Enums.ItemVariantsUsageOptions.DontUse;
	ProductsAndCharacteristics = ProductAttributes.UseVariants <> NotUseCharacteristics;		

	UseCharacteristics = FOUseProductCharacteristics And ProductsAndCharacteristics;
	KeepAccountingByBatch = FOUseSeriesProducts And TypeOfProductsUseSeries;
	
	Items.SelectedProductCertificatesCharacteristic.Visible = UseCharacteristics;
	Items.SelectedProductCertificatesSeries.Visible 			= KeepAccountingByBatch;
	
	TypesArray = Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	Items.CertificateType.ChoiceList.LoadValues(TypesArray);
	
	CommonClientServer.SetDynamicListFilterItem(
		Scope,
		"QualityCertificate",
		Catalogs.QualityCertificates.EmptyRef(),
		DataCompositionComparisonType.Equal);
			
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"Products",
		Catalogs.Products.EmptyRef());
			
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"ProductKind",
		Catalogs.ItemKinds.EmptyRef());
	
	If OnlyValidAsOfTheDate Then
		Items.Date.Enabled = True;
	Else	
		Items.Date.Enabled = False;
	EndIf;
	
	If Not AccessRight("Update", Metadata.Catalogs.QualityCertificates) Then
		Items.GroupCommandBarSetStatus.Enabled = False;
	EndIf;
	
	Date = CurrentSessionDate();
	
	TitleText = NStr("vi = 'Chứng nhận đã chọn (0)';
					|ru = 'Подобранные сертификаты (0)';
					|en = 'Picked certificates (0)'; fa = 'Picked certificates (0)';
					|it = 'Certificati selezionati (0)';
					|pl = 'Wybrane certyfikaty (0)';
					|tr = 'Seçilen sertifikalar (0)'");
	Items.TheGroupPickedUpCertificates.CollapsedRepresentationTitle = TitleText;
	Items.TheGroupPickedUpCertificates.Title = TitleText;
	
	ProductsLocalization.WhenCreatingOnServer_NomenclatureCertificates_ListForm(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_QualityCertificate" Then
		
		TypesArray = CreateListToSelectCertificateTypes();
		Items.CertificateType.ChoiceList.LoadValues(TypesArray);
		Items.QualityCertificates.Refresh();
		
		If Not Items.ScopeGroup.Hidden() Then
			Items.Scope.Refresh();
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If SelectedProductCertificates.Count() > 0
		And Not CertificatesAreSelected
		And Not ClosingInProgress Then
		
		Cancel = True;
		
		If Exit Then
			WarningText =  NStr("vi = 'Dữ liệu đã thay đổi.
				|Sẽ ngắt chọn chứng nhận đối với mặt hàng.';
				|ru = 'Данные были изменены.
				|Работа по подбору сертификатов для номенклатуры будет прервана.';
				|en = 'Data has changed.
				|Picking of quality certificates will be canceled.'; fa = 'Data has changed.
				|Picking of quality certificates will be canceled.';
				|it = 'I dati sono stati modificati. 
				| Il lavoro per la selezione dei certificati per articolo verrà interrotto.';
				|pl = 'Dane zostały zmienione.
				|Praca z wyborem certyfikatów dla towarów zostanie przerwana.';
				|tr = 'Veriler değiştirildi.
				|Öğe için sertifika seçimi çalışması kesintiye uğrayacaktır.'");
			Return;
		EndIf;
		
		ClosingNotification_ = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		QueryText = NStr("vi = 'Chứng nhận đã chọn sẽ không có hiệu lực đối với mặt hàng. Đặt chứng nhận tương ứng với mặt hàng?';
						|ru = 'Подобранные сертификаты не будут действовать для номенклатуры. Сопоставить сертификаты с номенклатурой?';
						|en = 'The picked certificates will not be valid for products. Map certificates to products?'; fa = 'The picked certificates will not be valid for products. Map certificates to products?';
						|it = 'I certificati selezionati non saranno validi per l''articolo. Confrontare i certificati con l''articolo?';
						|pl = 'Wybrane certyfikaty nie będą obowiązywać dla towarów. Zestawić certyfikaty z nazwami towarowymi?';
						|tr = 'Seçilen sertifikalar öğe için geçerli olmayacaktır. Sertifikaları öğeyle karşılaştır?'");
		
		ShowQueryBox(ClosingNotification_, QueryText, QuestionDialogMode.YesNoCancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure CertificateTypeOnChange(Item)
			
	CommonClientServer.SetDynamicListFilterItem(
		QualityCertificates,
		"CertificateType",
		CertificateType,
		DataCompositionComparisonType.Equal,,
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
Procedure NomenclatureSelectionOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(
		QualityCertificates,
		"Products",
		NomenclatureSelection);
		
	If ValueIsFilled(NomenclatureSelection) Then
					
		CommonClientServer.SetDynamicListParameter(
			QualityCertificates,
			"ProductKind",
			ProductKind(NomenclatureSelection));
			
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
			"ProductKind",
			PredefinedValue("Catalog.ItemKinds.EmptyRef"));
			
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

&AtClient
Procedure WhenChangingAttributesOfForm(Item)
	
	ProductsClientLocalization.WhenChangingDetails_CertificatesOfItem_FormOfList(Item, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQualityCertificates

&AtClient
Procedure QualityCertificatesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Var_Group Then
		Return;
	EndIf;
	
	Cancel = True;
	FormParameters = New Structure();
	
	If Copy Then
		CurrentData = Item.CurrentData;
		If CurrentData = Undefined Then
			Return;
		ElsIf CurrentData.IsFolder Then
			Return;
		EndIf;
		
		FormParameters.Insert("CopyingValue", CurrentData.Ref);
	Else
		FormParameters.Insert("Products", NomenclatureSelection);
		FormParameters.Insert("CertificateType", CertificateType);
	EndIf;
	
	OpenForm("Catalog.QualityCertificates.Form.ItemForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure QualityCertificatesOnActivateRow(Item)
	
	AttachIdleHandler("ProductCertificatesActivatingLine", 0.1, True);
	
EndProcedure

&AtClient
Procedure QualityCertificatesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	ElsIf CurrentData.IsFolder Then
		Return;
	EndIf;
	
	If ProductsClientLocalization.ChoosingStatusOfRosaccreditation(Field, Items) Then
		ProductsClientLocalization.WhenChoosingStatusOfRosaccreditation(Item, StandardProcessing, False);
		
		Return;
	EndIf;
	
	RowFilter = New Structure();
	RowFilter.Insert("Certificate", RowSelected);
	
	FoundRows = SelectedProductCertificates.FindRows(RowFilter);
	If FoundRows.Count() Then
		Return;
	EndIf;
	
	NewRow = SelectedProductCertificates.Add();
	NewRow.Certificate = RowSelected;
	UpdateHeaderMatchedCertificates();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersScope

&AtClient
Procedure ScopeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedProductCertificates

&AtClient
Procedure SelectedProductCertificatesSeriesStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure();
	FormParameters.Insert("ProductKind", OriginalProductKind);
	FormParameters.Insert("Products", OriginalProducts);
	FormParameters.Insert("Characteristic", Items.SelectedProductCertificates.CurrentData.Characteristic);
	FormParameters.Insert("ItemVariantsAreUsed", UseCharacteristics);
	
	OpenForm("Catalog.QualityCertificates.Form.ScopeChoiceFormBatch",
		FormParameters,
		,
		,
		,
		,
		New CallbackDescription("SelectedProductCertificatesSeriesStartChoiceCompletion", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectedProductCertificatesOnChange(Item)
	UpdateHeaderMatchedCertificates();
EndProcedure

&AtClient
Procedure SelectedProductCertificatesOnEditEnd(Item, NewRow, CancelEdit)
	UpdateHeaderMatchedCertificates();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	ClearMessages();
	If PickUpCertificatesOnServer() Then
		Notify("Write_QualityCertificate");
		CertificatesAreSelected = True;
		Close();
	EndIf;
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	Close();
	
EndProcedure

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
		MessageText = NStr("vi = 'Đối với chứng nhận mặt hàng ""%Certificate%"" không có hình ảnh để xem trước';
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
Procedure ExecuteFormCommand(Command)
	
	ProductsClientLocalization.ExecuteCommand_NomenclatureCertificates_ListForm(Command, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedProductCertificatesCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedProductCertificates.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
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
	ItemField.Field = New DataCompositionField(Items.SelectedProductCertificatesSeries.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedProductCertificates.Series");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối với tất cả sê-ri>';
													|ru = '<для всех серий>';
													|en = '<for all batches>'; fa = '<برای همه بچ‌ها>';
													|it = '<comune per tutte le serie>';
													|pl = '<dla wszystkich serii>';
													|tr = '<tüm partiler için>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectedProductCertificatesSeries.Name);
	
	SelectionGroupAnd = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	SelectionGroupAnd.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SelectedProductCertificates.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = SelectionGroupAnd.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseCharacteristics");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	Item.Appearance.SetParameterValue("Enabled", False);
	
	//
	ProductsLocalization.SetConditionalAppearanceOfListOfCertificatesOfNomenclature(ThisObject);
	
EndProcedure

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
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	ElsIf QuestionResult = DialogReturnCode.Yes Then
		
		If PickUpCertificatesOnServer() Then
			Notify("Write_QualityCertificate");
			CertificatesAreSelected = True;
			ClosingInProgress = True;
			Close();
			
		EndIf;
		Return;
		
	EndIf;
	
	ClosingInProgress = True;
	Close();
	
EndProcedure

&AtClient
Procedure SelectedProductCertificatesSeriesStartChoiceCompletion(Result, AdditionalParameters) Export
	
	Series = Result;
	Items.SelectedProductCertificates.CurrentData.Series = Series;
	
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

&AtClient
Procedure ProductCertificatesActivatingLine()
	
	CurrentRow = Items.QualityCertificates.CurrentData;
	If CurrentRow <> Undefined Then
		CommonClientServer.SetDynamicListFilterItem(
			Scope, "QualityCertificate", CurrentRow.Ref, DataCompositionComparisonType.Equal);
	Else
		CommonClientServer.SetDynamicListFilterItem(
			Scope,
			"QualityCertificate",
			PredefinedValue("Catalog.QualityCertificates.EmptyRef"),
			DataCompositionComparisonType.Equal);
	EndIf;
	
EndProcedure

&AtServer
Function ProductKind(Products)

	Return Common.ObjectAttributeValue(Products,"ProductKind");
		
EndFunction

&AtServer
Function PickUpCertificatesOnServer()

	TemplateError = NStr("vi = 'Chưa điền cột ""Chứng nhận"" tại dòng %LineNumber% trong danh sách ""Chứng nhận đã chọn""';
						|ru = 'Не заполнена колонка ""Сертификат"" в строке %LineNumber% списка ""Подобранные сертификаты""';
						|en = 'Column ""Certificate"" in line %LineNumber% of the ""Picked certificates"" list is not filled in'; fa = 'Column ""Certificate"" in line %LineNumber% of the ""Picked certificates"" list is not filled in';
						|it = 'La colonna ""Certificato"" nella riga %LineNumber% dell''elenco ""Certificati selezionati"" non è compilata';
						|pl = 'Nie wypełniono kolumny ""Certyfikat"" w wierszu %LineNumber% listy ""Wybrane certyfikaty""';
						|tr = '""Seçilen sertifikalar"" listesinin %LineNumber% satırında ""Sertifika"" sütunu doldurulmadı'");
	Error = False;
	
	LineNumber = 1;
	For Each LineOfSelectedProducts In SelectedProductCertificates Do
		If LineOfSelectedProducts.Certificate = Catalogs.QualityCertificates.EmptyRef() Then
			MessageText = StrReplace(TemplateError, "%LineNumber%", String(LineNumber));
			Field = CommonClientServer.PathToTabularSection("SelectedProductCertificates", LineNumber, "Certificate");
			Common.MessageToUser(MessageText,,Field);
			Error = True;
		EndIf;
		LineNumber = LineNumber + 1;
	EndDo;
	
	If Error Then
		Return False
	EndIf;
	
	ProductKind = ProductKind(OriginalProducts);

	RecordSet = InformationRegisters.QualityCertificateApplicationAreas.CreateRecordSet();
	RecordSet.Filter.ProductKind.Set(ProductKind);
	RecordSet.Filter.Products.Set(OriginalProducts);
	RecordSet.Read();
	ScopeRegisterTable = RecordSet.Unload();
	ScopeRegisterTableNew = ScopeRegisterTable.CopyColumns();
	
	RowFilter = New Structure();
	RowFilter.Insert("ProductKind", ProductKind);
	RowFilter.Insert("Products", OriginalProducts);
	
	For Each LineOfSelectedProducts In SelectedProductCertificates Do
		RowFilter.Insert("Characteristic", LineOfSelectedProducts.Characteristic);
		RowFilter.Insert("Series", LineOfSelectedProducts.Series);
		RowFilter.Insert("QualityCertificate", LineOfSelectedProducts.Certificate);
		
		FoundRows = ScopeRegisterTable.FindRows(RowFilter);
		
		If FoundRows.Count() = 0 Then
			NewRecord = ScopeRegisterTableNew.Add();
			FillPropertyValues(NewRecord, RowFilter);
		EndIf;
	EndDo;
	
	If ScopeRegisterTableNew.Count() > 1 Then
		ColumnsNames = "";
		For Each Column In ScopeRegisterTableNew.Columns Do
			If IsBlankString(ColumnsNames) Then
				ColumnsNames = Column.Name;
			Else
				ColumnsNames = ColumnsNames + ", " + Column.Name;
			EndIf;
		EndDo;
		ScopeRegisterTableNew.GroupBy(ColumnsNames);
	EndIf;
	
	RecordSet.Load(ScopeRegisterTableNew);
	RecordSet.Write(False);
	
	Return True;
	
EndFunction

&AtServer
Function OpenImageOnServer(QualityCertificate);
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	MAX(QualityCertificatesAttachedFiles.Ref) AS AttachedFile,
	|	COUNT(DISTINCT QualityCertificatesAttachedFiles.Ref) AS FilesCount,
	|	QualityCertificatesAttachedFiles.FileOwner
	|FROM
	|	Catalog.QualityCertificatesAttachedFiles AS QualityCertificatesAttachedFiles
	|WHERE
	|	QualityCertificatesAttachedFiles.FileOwner = &FileOwner
	|	AND QualityCertificatesAttachedFiles.DeletionMark = FALSE
	|
	|GROUP BY
	|	QualityCertificatesAttachedFiles.FileOwner";
	Query.SetParameter("FileOwner", QualityCertificate);
	
	Selection = Query.Execute().Select();	

	ReturnStructure = New Structure;
	
	If Selection.Next() Then
		If Selection.FilesCount > 1 Then
			ReturnStructure.Insert("Result", "ArrayOfImages");
		ElsIf Selection.FilesCount = 1 Then
			ReturnStructure.Insert("Result", "OneImage");
			ReturnStructure.Insert("AttachedFile", Selection.AttachedFile);
		EndIf;				
	Else
		ReturnStructure.Insert("Result", "NoImages");
	EndIf;	
			
	Return ReturnStructure;
	
EndFunction	

&AtServerNoContext
Function GenerateListOfTypes(Text)
	
	Return Catalogs.QualityCertificates.AutomaticSelectionOfCertificateTypes(Text);
	
EndFunction

&AtServerNoContext
Function CreateListToSelectCertificateTypes()
	
	Return Catalogs.QualityCertificates.CreateListToSelectCertificateTypes();
	
EndFunction

&AtClient
Procedure UpdateHeaderMatchedCertificates()
	
	TitleText = NStr("vi = 'Chứng nhận đã chọn (%Count%)';
					|ru = 'Подобранные сертификаты (%Count%)';
					|en = 'Picked certificates (%Count%)'; fa = 'Picked certificates (%Count%)';
					|it = 'Certificati selezionati (%Count%)';
					|pl = 'Wybrane certyfikaty (%Count%)';
					|tr = 'Seçilen sertifikalar (%Count%)'");	
	TitleText = StrReplace(TitleText,"%Count%",SelectedProductCertificates.Count());
	
	Items.TheGroupPickedUpCertificates.CollapsedRepresentationTitle = TitleText;
	Items.TheGroupPickedUpCertificates.Title = TitleText;

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
