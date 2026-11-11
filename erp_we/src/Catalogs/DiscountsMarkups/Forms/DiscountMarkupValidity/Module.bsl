
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FillPropertyValues(ThisObject, DiscountsMarkupsServer.StructureOfDiscountSourcesAccordingToFederalLaw());
	
	DiscountMarkup = Parameters.DiscountMarkup;
	Date = CurrentSessionDate();
	SliceDate = Date;
	
	DynamicLists = New Array;
	DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	DynamicLists.Add(UseInLoyaltyCards);
	DynamicLists.Add(UseInWarehouses);
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"CurrentDate",
			SliceDate,
			True);
			
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"DiscountMarkup",
			DiscountMarkup,
			True);
			
	EndDo;
	
	EditingDiscountsMarkupsIsAvailable = AccessRight("Update", Metadata.Catalogs.DiscountsMarkups);
	
	Items.UseInWarehousesUseInWarehousesSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesUseInWarehousesSetTheStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesContextMenuUseInWarehousesSetTheStatusToValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesContextMenuTheUseOfWarehousesSetStatusIsNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	
	Items.TheUseOfLoyaltyCardsUseLoyaltyCardsToSetTheStatusIsNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.TheUseOfLoyaltyCardsUseLoyaltyCardsToSetTheStatusToValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInLoyaltyCardsContextMenuUseInLoyaltyCardsSetStatusDoesNotApply.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInLoyaltyCardsContextMenuUseInLoyaltyCardsSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;

	Items.UseInIndividualCustomerAgreementsUseInCustomerAgreementsSetTheStatusToValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInIndividualCustomerAgreementsUseInCustomerAgreementsSetStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInIndividualAgreementsWithCustomersContextMenuUseInIndividualAgreementsWithClientsToSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInIndividualAgreementsWithCustomersContextMenuUseInIndividualCustomerAgreementsToSetTheStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;

	Items.UseInStandardCustomerAgreementsUseInCustomerAgreementsSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInStandardCustomerAgreementsUseInCustomerAgreementsSetTheStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInStandardAgreementsWithCustomersContextMenuUseInStandardAgreementsWithClientsToSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInStandardAgreementsWithCustomersContextMenuUseInStandardAgreementsWithClientsToSetTheStatusDoesNotApply.Visible = EditingDiscountsMarkupsIsAvailable;
	
	CommonClientServer.SetDynamicListFilterItem(
		UseInWarehouses,
		"Status",
		Enums.DiscountValidityStatuses.Valid,
		DataCompositionComparisonType.Equal,
		,
		TheUseOfWarehousesToDisplayTheDiscountMargins <> "All");
		
	CommonClientServer.SetDynamicListFilterItem(
		UseInIndividualAgreementsWithCustomers,
		"Status",
		Enums.DiscountValidityStatuses.Valid,
		DataCompositionComparisonType.Equal,
		,
		UseInIndividualAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
		
	CommonClientServer.SetDynamicListFilterItem(
		UseInStandardAgreementsWithCustomers,
		"Status",
		Enums.DiscountValidityStatuses.Valid,
		DataCompositionComparisonType.Equal,
		,
		UseInStandardAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
		
	CommonClientServer.SetDynamicListFilterItem(
		UseInLoyaltyCards,
		"Status",
		Enums.DiscountValidityStatuses.Valid,
		DataCompositionComparisonType.Equal,
		,
		UseInLoyaltyCardsOptionToDisplayDiscountsMarkups <> "All");
		
	UpdateUsageOfDiscountsMarkups();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ValidityOfDiscountsMarkups" And Parameter.DiscountMarkup.Find(DiscountMarkup) <> Undefined Then
		Items.UseInLoyaltyCards.Refresh();
		Items.UseInIndividualAgreementsWithCustomers.Refresh();
		Items.UseInStandardAgreementsWithCustomers.Refresh();
		Items.UseInWarehouses.Refresh();
		UpdateUsageOfDiscountsMarkups();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SliceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateDataOnServer();
	
EndProcedure

&AtClient
Procedure SliceDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SliceDate = Date;
	
	UpdateDataOnServer();
	
EndProcedure

&AtClient
Procedure UseInWarehousesOptionForDisplayingDiscountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		UseInWarehouses,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		TheUseOfWarehousesToDisplayTheDiscountMargins <> "All");
		
EndProcedure

&AtClient
Procedure UseInIndividualAgreementsWithCustomersOptionToDisplayDiscountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		UseInIndividualAgreementsWithCustomers,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		UseInIndividualAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
		
EndProcedure

&AtClient
Procedure TheUseOfStandardAgreementsWithCustomersTheOptionOfShowDiscountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		UseInStandardAgreementsWithCustomers,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		UseInStandardAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
		
EndProcedure

&AtClient
Procedure UseInLoyaltyCardsOptionForDisplayingDiscountsOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(
		UseInLoyaltyCards,
		"Status",
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
		DataCompositionComparisonType.Equal,
		,
		UseInLoyaltyCardsOptionToDisplayDiscountsMarkups <> "All");
		
EndProcedure

&AtClient
Procedure InformationOnDiscountValidityURLProcessing(Item, Var_URL, StandardProcessing)
	
	StandardProcessing = False;
	If Var_URL = "ChangeOverallStatus" Then
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("DiscountMarkup", DiscountMarkup);
		OpeningParameters.Insert("Source", PredefinedValue("Catalog.Warehouses.EmptyRef"));
		OpenForm("Catalog.DiscountsMarkups.Form.SettingOfValidityStatus", OpeningParameters);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure UseInWarehousesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.UseInWarehousesWarehouse Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseInLoyaltyCardsSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.UseInLoyaltyCardsLoyaltyCardKind Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseInIndividualAgreementsWithCustomersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.UseInIndividualAgreementsWithCustomersTerms Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure UseInStandardAgreementsWithCustomersSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field <> Items.UseInStandardAgreementsWithCustomersTerms Then
		StandardProcessing = False;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure TheUseOfWarehousesSetStatusIsNotValid(Command)
	
	Sources = New Array;
	For Each RowID In Items.UseInWarehouses.SelectedRows Do
		Sources.Add(Items.UseInWarehouses.RowData(RowID).Warehouse);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"));
	
EndProcedure

&AtClient
Procedure UseInWarehousesSetTheStatusToValid(Command)
	
	Sources = New Array;
	For Each RowID In Items.UseInWarehouses.SelectedRows Do
		Sources.Add(Items.UseInWarehouses.RowData(RowID).Warehouse);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure UseInLoyaltyCardsSetStatusDoesNotApply(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInLoyaltyCards.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"));
	
EndProcedure

&AtClient
Procedure UseInLoyaltyCardsSetTheStatusValid(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInLoyaltyCards.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure UseInIndividualCustomerAgreementsToSetTheStatusNotValid(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInIndividualAgreementsWithCustomers.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"));
	
EndProcedure

&AtClient
Procedure UseInIndividualAgreementsWithClientsToSetTheStatusValid(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInIndividualAgreementsWithCustomers.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure UseInStandardAgreementsWithClientsToSetTheStatusDoesNotApply(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInStandardAgreementsWithCustomers.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"));
	
EndProcedure

&AtClient
Procedure UseInStandardAgreementsWithClientsToSetTheStatusValid(Command)
	
	Sources = New Array;
	For Each Source In Items.UseInStandardAgreementsWithCustomers.SelectedRows Do
		Sources.Add(Source);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure HistoryOfActionsInTheWarehouse(Command)
	
	CurrentData = Items.UseInWarehouses.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.Warehouse);
	
EndProcedure

&AtClient
Procedure TheHistoryOfActionsInTheFormOfLoyaltyCards(Command)
	
	CurrentData = Items.UseInLoyaltyCards.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.LoyaltyCardKind);
	
EndProcedure

&AtClient
Procedure HistoryOfActionInAnIndividualAgreement(Command)
	
	CurrentData = Items.UseInIndividualAgreementsWithCustomers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.Terms);
	
EndProcedure

&AtClient
Procedure TheHistoryOfActionsInAModelAgreement(Command)
	
	CurrentData = Items.UseInStandardAgreementsWithCustomers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.Terms);
	
EndProcedure

&AtClient
Procedure OK(Command)
	
	Close(Undefined);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInLoyaltyCardsEndDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInLoyaltyCards.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInLoyaltyCards.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInIndividualAgreementsWithCustomersEndDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInIndividualAgreementsWithCustomers.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInIndividualAgreementsWithCustomers.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInStandardAgreementsWithCustomersEndDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInStandardAgreementsWithCustomers.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInStandardAgreementsWithCustomers.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInWarehousesEndDate.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInWarehouses.EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInWarehouses.StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInWarehouses.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInWarehouses.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInWarehousesWarehouse.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInWarehouses.Warehouse");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.Warehouses.EmptyRef();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tất cả kho bãi';
													|ru = 'Все склады';
													|en = 'All warehouses'; fa = 'All warehouses';
													|it = 'Tutti i magazzini';
													|pl = 'Wszystkie magazyny';
													|tr = 'Tüm ambarlar'"));
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInLoyaltyCards.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInLoyaltyCards.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInIndividualAgreementsWithCustomers.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInIndividualAgreementsWithCustomers.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.UseInStandardAgreementsWithCustomers.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UseInStandardAgreementsWithCustomers.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
EndProcedure

&AtClient
Procedure OpenStatusChangeForm(Source, Status)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("StartDate", SliceDate);
	OpeningParameters.Insert("DiscountMarkup", DiscountMarkup);
	OpeningParameters.Insert("Source", Source);
	OpeningParameters.Insert("Status", Status);
	
	OpenForm(
		"Catalog.DiscountsMarkups.Form.SettingOfValidityStatus",
		OpeningParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure OpenHistoryForm(Source)
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Source", Source);
	OpeningParameters.Insert("DiscountMarkup", DiscountMarkup);
	OpenForm(
		"Catalog.DiscountsMarkups.Form.DiscountMarkupValidityHistory",
		OpeningParameters,
		ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateDataOnServer()
	
	DynamicLists = New Array;
	DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	DynamicLists.Add(UseInLoyaltyCards);
	DynamicLists.Add(UseInWarehouses);
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"CurrentDate",
			SliceDate,
			True);
			
	EndDo;
	
	UpdateUsageOfDiscountsMarkups();
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups()
	
	AdditionalCommand = "ChangeOverallStatus";
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(DiscountMarkup, SliceDate);
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount,
	                                                                                AdditionalCommand);
	DiscountsMarkupsServer.GenerateInformationAboutNumberOfDiscountsUsed(ThisObject, UsingMarkUpDiscount);
	
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
	If Item.Name = "sh_ShamsiInput_F_SliceDate" Then
		SliceDateOnChange(Items.SliceDate);
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
