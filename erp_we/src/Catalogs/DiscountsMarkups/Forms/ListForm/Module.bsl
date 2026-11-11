
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Date = CurrentSessionDate();
	
	UseSeveralWarehouses                   = GetFunctionalOption("UseSeveralWarehouses")
	                                                 And AccessRight("Read", Metadata.Catalogs.Warehouses);
	
	UseStandardTermsOfSalesWithCustomers        = GetFunctionalOption("UseStandardTermsOfSalesWithCustomers")
	                                                 And AccessRight("Read", Metadata.Catalogs.TermsOfSale);
	
	UseCustomerTermsOfSales = GetFunctionalOption("UseCustomerTermsOfSales")
	                                                 And AccessRight("Read", Metadata.Catalogs.TermsOfSale);
	
	UseLoyaltyCards                    = GetFunctionalOption("UseLoyaltyCards")
	                                                 And AccessRight("Read", Metadata.Catalogs.LoyaltyCardKinds);

	Items.GroupIndividualAgreements.Visible      = UseCustomerTermsOfSales;
	Items.ValidInIndividualAgreements.Visible = UseCustomerTermsOfSales;
	Items.AGroupOfModelAgreements.Visible             = UseStandardTermsOfSalesWithCustomers;
	Items.ValidInStandardAgreements.Visible        = UseStandardTermsOfSalesWithCustomers;
	Items.LoyaltyCardGroup.Visible               = UseLoyaltyCards;
	Items.ValidInLoyaltyCards.Visible          = UseLoyaltyCards;
	Items.GroupWarehouses.Visible                        = UseSeveralWarehouses;
	Items.ValidInWarehouses.Visible                  = UseSeveralWarehouses;
	
	OverridePropertiesOfDynamicLists();
	
	EditingDiscountsMarkupsIsAvailable = AccessRight("Update", Metadata.Catalogs.DiscountsMarkups);
	EditingOfAgreementsWithClientsIsAvailable = AccessRight("Update", Metadata.InformationRegisters.ValidityOfDiscountsMarkups);
	
	Items.SetStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.SetTheStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	
	Items.UseInWarehousesUseInWarehousesSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesUseInWarehousesSetTheStatusNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesContextMenuUseInWarehousesSetTheStatusToValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInWarehousesContextMenuTheUseOfWarehousesSetStatusIsNotValid.Visible = EditingDiscountsMarkupsIsAvailable;

	Items.TheUseOfLoyaltyCardsUseLoyaltyCardsToSetTheStatusToValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.TheUseOfLoyaltyCardsUseLoyaltyCardsToSetTheStatusIsNotValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInLoyaltyCardsContextMenuUseInLoyaltyCardsSetTheStatusValid.Visible = EditingDiscountsMarkupsIsAvailable;
	Items.UseInLoyaltyCardsContextMenuUseInLoyaltyCardsSetStatusDoesNotApply.Visible = EditingDiscountsMarkupsIsAvailable;

	Items.UseInIndividualCustomerAgreementsUseInCustomerAgreementsSetTheStatusToValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInIndividualCustomerAgreementsUseInCustomerAgreementsSetStatusNotValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInIndividualAgreementsWithCustomersContextMenuUseInIndividualAgreementsWithClientsToSetTheStatusValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInIndividualAgreementsWithCustomersContextMenuUseInIndividualCustomerAgreementsToSetTheStatusNotValid.Visible = EditingOfAgreementsWithClientsIsAvailable;

	Items.UseInStandardCustomerAgreementsUseInCustomerAgreementsSetTheStatusValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInStandardCustomerAgreementsUseInCustomerAgreementsSetTheStatusNotValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInStandardAgreementsWithCustomersContextMenuUseInStandardAgreementsWithClientsToSetTheStatusValid.Visible = EditingOfAgreementsWithClientsIsAvailable;
	Items.UseInStandardAgreementsWithCustomersContextMenuUseInStandardAgreementsWithClientsToSetTheStatusDoesNotApply.Visible = EditingOfAgreementsWithClientsIsAvailable;
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	SliceDate = CurrentSessionDate();
	
	DynamicLists = New Array;
	If UseCustomerTermsOfSales Then
		DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	EndIf;
	If UseStandardTermsOfSalesWithCustomers Then
		DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	EndIf;
	If UseLoyaltyCards Then
		DynamicLists.Add(UseInLoyaltyCards);
	EndIf;
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;
	DynamicLists.Add(List);
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"CurrentDate",
			SliceDate,
			True);
			
		If DynamicList = List Then
			Continue;
		EndIf;
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"DiscountMarkup",
			Catalogs.DiscountsMarkups.EmptyRef(),
			True);
			
	EndDo;
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"DefaultWarehouse",
		Catalogs.Warehouses.EmptyRef(),
		True);
		
	If UseSeveralWarehouses Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInWarehouses,
			"Status",
			Enums.DiscountValidityStatuses.Valid,
			DataCompositionComparisonType.Equal,
			,
			TheUseOfWarehousesToDisplayTheDiscountMargins <> "All");
	EndIf;
		
	If UseStandardTermsOfSalesWithCustomers Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInStandardAgreementsWithCustomers,
			"Status",
			Enums.DiscountValidityStatuses.Valid,
			DataCompositionComparisonType.Equal,
			,
			UseInStandardAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
	EndIf;
	
	If UseCustomerTermsOfSales Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInIndividualAgreementsWithCustomers,
			"Status",
			Enums.DiscountValidityStatuses.Valid,
			DataCompositionComparisonType.Equal,
			,
			UseInIndividualAgreementsWithCustomersOptionToDisplayDiscountsMarkups <> "All");
	EndIf;
	
	If UseLoyaltyCards Then
		CommonClientServer.SetDynamicListFilterItem(
			UseInLoyaltyCards,
			"Status",
			Enums.DiscountValidityStatuses.Valid,
			DataCompositionComparisonType.Equal,
			,
			UseInLoyaltyCardsOptionToDisplayDiscountsMarkups <> "All");
	EndIf;
	
	UseSimplifiedMode =   Not UseSeveralWarehouses
	                              And Not UseCustomerTermsOfSales
	                              And Not UseStandardTermsOfSalesWithCustomers
	                              And Not UseLoyaltyCards;
	
	Items.GroupUsingTheCurrentDiscount.Visible = Not UseSimplifiedMode;
	
	Items.ValidInWarehouses.Visible                  = UseSeveralWarehouses;
	Items.ValidInLoyaltyCards.Visible          = UseLoyaltyCards;
	Items.ValidInIndividualAgreements.Visible = UseCustomerTermsOfSales;
	Items.ValidInStandardAgreements.Visible        = UseStandardTermsOfSalesWithCustomers;
	
	If UseSimplifiedMode Then
		Items.SetStatus.Title = NStr("vi = 'Đặt trạng thái';
									|ru = 'Установить статус';
									|en = 'Set status'; fa = 'تعیین وضعیت';
									|it = 'Impostare stato';
									|pl = 'Ustaw status';
									|tr = 'Durumu ayarla'");
	Else
		Items.SetStatus.Title = NStr("vi = 'Đặt trạng thái chung';
									|ru = 'Установить общий статус';
									|en = 'Set general status'; fa = 'تعیین وضعیت کلی';
									|it = 'Impostare lo stato comune';
									|pl = 'Ustaw wspólny status';
									|tr = 'Genel durumu ayarla'");
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.GroupCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	CommonClientServer.SetFormItemProperty(
		Items,
		"GroupCreate",
		"Visible",
		AccessRight("InteractiveInsert", Metadata.Catalogs.DiscountsMarkups));
	
	DiscountsMarkupsServer.AddCommandsToCreateNewDiscountsMarkups(ThisObject, Items.GroupCreate);
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure UpdateDataOnServer(DiscountMarkup)
	Items.List.Refresh();
	Items.UseInLoyaltyCards.Refresh();
	Items.UseInIndividualAgreementsWithCustomers.Refresh();
	Items.UseInStandardAgreementsWithCustomers.Refresh();
	Items.UseInWarehouses.Refresh();
	UpdateUsageOfDiscountsMarkups(DiscountMarkup);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_ValidityOfDiscountsMarkups" Then
		DiscountMarkup = CurDiscount();
		UpdateDataOnServer(DiscountMarkup);
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	Status = Settings.Get("Status");
	SetSelectionByStatus(ThisForm);
	
EndProcedure

#EndRegion

#Region ListEventHandlers

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("Attachable_ListOnActivateRow", 0.1, True);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure StatusFilterOnChange(Item)
	
	SetSelectionByStatus(ThisForm);
	
EndProcedure

&AtClient
Procedure FilterSliceDateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	DynamicLists = New Array;
	If UseCustomerTermsOfSales Then
		DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	EndIf;
	If UseStandardTermsOfSalesWithCustomers Then
		DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	EndIf;
	If UseLoyaltyCards Then
		DynamicLists.Add(UseInLoyaltyCards);
	EndIf;
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;
	DynamicLists.Add(List);
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"CurrentDate",
			SliceDate,
			True);
			
	EndDo;
	
EndProcedure

&AtClient
Procedure FilterSliceDateClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	SliceDate = Date;
	
	DynamicLists = New Array;
	If UseCustomerTermsOfSales Then
		DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	EndIf;
	If UseStandardTermsOfSalesWithCustomers Then
		DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	EndIf;
	If UseLoyaltyCards Then
		DynamicLists.Add(UseInLoyaltyCards);
	EndIf;
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;
	DynamicLists.Add(List);
	
	For Each DynamicList In DynamicLists Do
		
		CommonClientServer.SetDynamicListParameter(
			DynamicList,
			"CurrentDate",
			SliceDate,
			True);
			
	EndDo;
	
EndProcedure

&AtClient
Procedure ListDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	
	If String = Undefined Or String = PredefinedValue("Catalog.DiscountsMarkups.EmptyRef") Then
		StandardProcessing = False;
		DragParameters.Action = DragAction.Cancel;
	EndIf;
	
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
Procedure Attachable_ExecuteCommandToAddDiscountMarkUp(Command)
	
	DiscountsMarkupsClient.ProcessCommandToAddDiscountMarkUp(
		ThisObject,
		Command,
		Items.List.CurrentRow);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	
	ExecuteCommandAtServer(ExecutionParameters);
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
	
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure SetTheStatusNotValid(Command)
	
	Sources = New Array;
	Sources.Add(PredefinedValue("Catalog.Warehouses.EmptyRef"));
	
	DiscountsMarkups = New Array;
	For Each DiscountMarkup In Items.List.SelectedRows Do
		RowData = Items.List.RowData(DiscountMarkup);
		If RowData.IsFolder Then
			Continue;
		EndIf;
		DiscountsMarkups.Add(DiscountMarkup);
	EndDo;
	
	If DiscountsMarkups.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn chiết khấu (phụ thu)';
										|ru = 'Не выбраны скидки (наценки)';
										|en = 'Discounts (markups) are not selected'; fa = 'Discounts (markups) are not selected';
										|it = 'Non sono selezionati gli sconti (sovrapprezzi)';
										|pl = 'Nie wybrano rabatów (marż)';
										|tr = 'İndirimler (zamlar) seçilmedi'"));
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		DiscountsMarkups,
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.NotValid"));
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	Sources = New Array;
	Sources.Add(PredefinedValue("Catalog.Warehouses.EmptyRef"));
	
	DiscountsMarkups = New Array;
	For Each DiscountMarkup In Items.List.SelectedRows Do
		RowData = Items.List.RowData(DiscountMarkup);
		If RowData.IsFolder Then
			Continue;
		EndIf;
		DiscountsMarkups.Add(DiscountMarkup);
	EndDo;
	
	If DiscountsMarkups.Count() = 0 Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn chiết khấu (phụ thu)';
										|ru = 'Не выбраны скидки (наценки)';
										|en = 'Discounts (markups) are not selected'; fa = 'Discounts (markups) are not selected';
										|it = 'Non sono selezionati gli sconti (sovrapprezzi)';
										|pl = 'Nie wybrano rabatów (marż)';
										|tr = 'İndirimler (zamlar) seçilmedi'"));
		Return;
	EndIf;
	
	OpenStatusChangeForm(
		DiscountsMarkups,
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure TheUseOfWarehousesSetStatusIsNotValid(Command)
	
	Sources = New Array;
	For Each RowID In Items.UseInWarehouses.SelectedRows Do
		Sources.Add(Items.UseInWarehouses.RowData(RowID).Warehouse);
	EndDo;
	
	If Sources.Count() = 0 Then
		Return;
	EndIf;
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
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
	
	DiscountMarkup = CurDiscount();
	
	OpenStatusChangeForm(
		DiscountMarkup,
		Sources,
		PredefinedValue("Enum.DiscountValidityStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure ActionHistory(Command)
	
	OpenHistoryForm(PredefinedValue("Catalog.Warehouses.EmptyRef"));
	
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
Procedure TheHistoryOfActionsInAModelAgreement(Command)
	
	CurrentData = Items.UseInStandardAgreementsWithCustomers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.Terms);
	
EndProcedure

&AtClient
Procedure HistoryOfActionInAnIndividualAgreement(Command)
	
	CurrentData = Items.UseInIndividualAgreementsWithCustomers.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	OpenHistoryForm(CurrentData.Terms);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ListOfConditionalAppearance = List.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
	ListOfUsageInLoyaltyCardsConditionalAppearance = UseInLoyaltyCards.SettingsComposer.Settings.ConditionalAppearance;
	ListOfUsageInLoyaltyCardsConditionalAppearance.Items.Clear();
	
	ListUseInIndividualAgreementsWithClientsConditionalAppearance = UseInIndividualAgreementsWithCustomers.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInIndividualAgreementsWithClientsConditionalAppearance.Items.Clear();
	
	ListUseInStandardAgreementsWithClientsConditionalAppearance = UseInStandardAgreementsWithCustomers.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInStandardAgreementsWithClientsConditionalAppearance.Items.Clear();
	
	ListUseInWarehousesConditionalAppearance = UseInWarehouses.SettingsComposer.Settings.ConditionalAppearance;
	ListUseInWarehousesConditionalAppearance.Items.Clear();

	//

	Item = ListOfConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Managed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	Item.Appearance.SetParameterValue("TextColor", New Color(0, 128, 0));

	If UseLoyaltyCards  Then
		
		//
		
		Item = ListOfUsageInLoyaltyCardsConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("EndDate");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("EndDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = '00010101';

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StartDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = '00010101';

		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
														|ru = '<бессрочно>';
														|en = '<permanent>'; fa = '<دائمی>';
														|it = '<illimitato>';
														|pl = '<permanent>';
														|tr = '<süresiz>'"));
		
	EndIf;
	
	If UseCustomerTermsOfSales  Then
		
		//

		Item = ListUseInIndividualAgreementsWithClientsConditionalAppearance.Items.Add();
	
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("EndDate");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("EndDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = '00010101';

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StartDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = '00010101';

		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
														|ru = '<бессрочно>';
														|en = '<permanent>'; fa = '<دائمی>';
														|it = '<illimitato>';
														|pl = '<permanent>';
														|tr = '<süresiz>'"));
		
		//
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("EndDate");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("EndDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = '00010101';

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StartDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = '00010101';

		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
														|ru = '<бессрочно>';
														|en = '<permanent>'; fa = '<دائمی>';
														|it = '<illimitato>';
														|pl = '<permanent>';
														|tr = '<süresiz>'"));
		
	EndIf;
	
	If UseStandardTermsOfSalesWithCustomers Then
		
		//

		Item = ListUseInStandardAgreementsWithClientsConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("EndDate");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("EndDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = '00010101';

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StartDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = '00010101';

		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
														|ru = '<бессрочно>';
														|en = '<permanent>'; fa = '<دائمی>';
														|it = '<illimitato>';
														|pl = '<permanent>';
														|tr = '<süresiz>'"));
		
	EndIf;
	
	If UseSeveralWarehouses Then
	
		//

		Item = ListUseInWarehousesConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("EndDate");
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("EndDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = '00010101';

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("StartDate");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
		ItemFilter.RightValue = '00010101';

		Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
														|ru = '<бессрочно>';
														|en = '<permanent>'; fa = '<دائمی>';
														|it = '<illimitato>';
														|pl = '<permanent>';
														|tr = '<süresiz>'"));
	
	EndIf;
	
	If UseSeveralWarehouses Then
	
		//

		Item = ListUseInWarehousesConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If UseLoyaltyCards Then
	
		//

		Item = ListOfUsageInLoyaltyCardsConditionalAppearance .Items.Add();
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If UseCustomerTermsOfSales Then
	
		//

		Item = ListUseInIndividualAgreementsWithClientsConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	If UseStandardTermsOfSalesWithCustomers Then
	
		//

		Item = ListUseInStandardAgreementsWithClientsConditionalAppearance.Items.Add();

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	EndIf;
	
	//

	Item = ListOfConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("EndDate");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("EndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = '00010101';

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("StartDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = '00010101';

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không thời hạn>';
													|ru = '<бессрочно>';
													|en = '<permanent>'; fa = '<دائمی>';
													|it = '<illimitato>';
													|pl = '<permanent>';
													|tr = '<süresiz>'"));
	
	//

	Item = ListOfConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;
	
	If UseSeveralWarehouses Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	EndIf;
	
	If UseLoyaltyCards Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	EndIf;

	If UseCustomerTermsOfSales Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	EndIf;
	
	If UseStandardTermsOfSalesWithCustomers Then
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
	EndIf;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);
	
	If UseCustomerTermsOfSales Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực hạn chế';
														|ru = 'Действует с ограничениями';
														|en = 'Valid with limitations'; fa = 'Valid with limitations';
														|it = 'Valido con delle limitazioni';
														|pl = 'Obowiązuje z ograniczeniami';
														|tr = 'Kısıtlamalarla geçerlidir'"));
	
	EndIf;
	
	If UseStandardTermsOfSalesWithCustomers Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực hạn chế';
														|ru = 'Действует с ограничениями';
														|en = 'Valid with limitations'; fa = 'Valid with limitations';
														|it = 'Valido con delle limitazioni';
														|pl = 'Obowiązuje z ograniczeniami';
														|tr = 'Kısıtlamalarla geçerlidir'"));
	
	EndIf;
	
	If UseLoyaltyCards Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực hạn chế';
														|ru = 'Действует с ограничениями';
														|en = 'Valid with limitations'; fa = 'Valid with limitations';
														|it = 'Valido con delle limitazioni';
														|pl = 'Obowiązuje z ograniczeniami';
														|tr = 'Kısıtlamalarla geçerlidir'"));
	
	EndIf;
	
	If UseSeveralWarehouses Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực hạn chế';
														|ru = 'Действует с ограничениями';
														|en = 'Valid with limitations'; fa = 'Valid with limitations';
														|it = 'Valido con delle limitazioni';
														|pl = 'Obowiązuje z ograniczeniami';
														|tr = 'Kısıtlamalarla geçerlidir'"));
	
	EndIf;
	
	If UseSeveralWarehouses Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực trong kho bãi';
														|ru = 'Действует на складах';
														|en = 'Valid in warehouses'; fa = 'معتبر در انبارها';
														|it = 'Valido nei magazzini';
														|pl = 'Obowiązuje w magazynach';
														|tr = 'Depolarda geçerlidir'"));
	
	EndIf;
	
	If UseLoyaltyCards Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực trong thẻ khách hàng thân thiết';
														|ru = 'Действует в картах лояльности';
														|en = 'Valid in loyalty cards'; fa = 'معتبر در کارت‌های وفاداری';
														|it = 'Valido per le carte della fedeltà';
														|pl = 'Obowiązuje dla kart lojalnościowych';
														|tr = 'Sadakat kartlarında geçerlidir'"));
	
	EndIf;
	
	If UseCustomerTermsOfSales
		Or UseStandardTermsOfSalesWithCustomers Then
	
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực trong thỏa thuận';
														|ru = 'Действует в соглашениях';
														|en = 'Valid in agreements'; fa = 'Valid in agreements';
														|it = 'Valido negli accordi';
														|pl = 'Obowiązuje w porozumieniach';
														|tr = 'Anlaşmalarda geçerlidir'"));
		
		//

		Item = ListOfConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField("Status");

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("Status");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Enums.DiscountValidityStatuses.NotValid;

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInWarehouses");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInLoyaltyCards");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInStandardAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ValidInIndividualAgreements");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = True;
		
		Item.Appearance.SetParameterValue("Text", NStr("vi = 'Có hiệu lực trong thỏa thuận';
														|ru = 'Действует в соглашениях';
														|en = 'Valid in agreements'; fa = 'Valid in agreements';
														|it = 'Valido negli accordi';
														|pl = 'Obowiązuje w porozumieniach';
														|tr = 'Anlaşmalarda geçerlidir'"));
	
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ListOnActivateRow()
	
	DiscountMarkup = CurDiscount();
	If DiscountMarkup <> ActivatedDiscountMarkup Then
		ListWhenActivatingLineOnServer(DiscountMarkup);
		ActivatedDiscountMarkup = DiscountMarkup;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetSelectionByStatus(Form)
	
	TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items.Clear();
	
	If ValueIsFilled(Form.Status) Then
		
		FilterGroup = CommonClientServer.CreateFilterItemGroup(
			TMCommonUseClientServer.GetDynamicListSelection(Form.List).Items, "PickingByStatuses",
			DataCompositionFilterItemsGroupType.OrGroup);
		
		CommonClientServer.SetFilterItem(
			FilterGroup,
			"Status",
			PredefinedValue("Enum.DiscountValidityStatuses.Valid"),
			DataCompositionComparisonType.Equal,
			,
			ValueIsFilled(Form.Status));
			
		If Form.UseSeveralWarehouses Then
			CommonClientServer.SetFilterItem(
				FilterGroup,
				"ValidInWarehouses",
				True,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Form.Status));
		EndIf;
		
		If Form.UseLoyaltyCards Then
			CommonClientServer.SetFilterItem(
				FilterGroup,
				"ValidInLoyaltyCards",
				True,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Form.Status));
		EndIf;
		
		If Form.UseStandardTermsOfSalesWithCustomers Then
			CommonClientServer.SetFilterItem(
				FilterGroup,
				"ValidInStandardAgreements",
				True,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Form.Status));
		EndIf;
		
		If Form.UseCustomerTermsOfSales Then
			CommonClientServer.SetFilterItem(
				FilterGroup,
				"ValidInIndividualAgreements",
				True,
				DataCompositionComparisonType.Equal,
				,
				ValueIsFilled(Form.Status));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function CurDiscount()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return Undefined;
	EndIf;
	
	If CurrentData.IsFolder Then
		Return Undefined;
	Else
		Return CurrentData.Ref;
	EndIf;
	
EndFunction

&AtClient
Procedure OpenStatusChangeForm(DiscountMarkup, Source, Status)
	
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
	
	DiscountMarkup = CurDiscount();
	If DiscountMarkup = Undefined Then
		ShowMessageBox(Undefined, NStr("vi = 'Chưa chọn chiết khấu (phụ thu)';
										|ru = 'Не выбрана скидка (наценка)';
										|en = 'Discount (markup) is not selected'; fa = 'Discount (markup) is not selected';
										|it = 'Non è selezionato lo sconto (sovrapprezzo)';
										|pl = 'Nie wybrano rabatu (marży)';
										|tr = 'İndirim (zam) seçilmedi'"));
		Return;
	EndIf;
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Source", Source);
	OpeningParameters.Insert("DiscountMarkup", DiscountMarkup);
	OpenForm(
		"Catalog.DiscountsMarkups.Form.DiscountMarkupValidityHistory",
		OpeningParameters,
		ThisForm);
	
EndProcedure

&AtServer
Procedure UpdateUsageOfDiscountsMarkups(DiscountMarkup)
	
	UsingMarkUpDiscount = DiscountsMarkupsServer.UsingMarkUpDiscount(DiscountMarkup, CurrentSessionDate());
	DiscountsMarkupsServer.CreateInformationLabelUsingDiscountsMargins(InformationOnDiscountValidity,
	                                                                                UsingMarkUpDiscount);
	DiscountsMarkupsServer.GenerateInformationAboutNumberOfDiscountsUsed(ThisObject, UsingMarkUpDiscount);
	
EndProcedure

&AtServer
Procedure ListWhenActivatingLineOnServer(DiscountMarkup)
	
	DynamicLists = New Array;
	If UseCustomerTermsOfSales Then
		DynamicLists.Add(UseInIndividualAgreementsWithCustomers);
	EndIf;
	If UseStandardTermsOfSalesWithCustomers Then
		DynamicLists.Add(UseInStandardAgreementsWithCustomers);
	EndIf;
	If UseLoyaltyCards Then
		DynamicLists.Add(UseInLoyaltyCards);
	EndIf;
	If UseSeveralWarehouses Then
		DynamicLists.Add(UseInWarehouses);
	EndIf;
	
	Items.GroupUsingTheCurrentDiscount.Enabled = DiscountMarkup <> Undefined;
	
	If DiscountMarkup = Undefined Then
		
		For Each DynamicList In DynamicLists Do
			
			CommonClientServer.SetDynamicListParameter(
				DynamicList,
				"DiscountMarkup",
				PredefinedValue("Catalog.DiscountsMarkups.EmptyRef"),
				True);
			
		EndDo;
		
	Else
		
		For Each DynamicList In DynamicLists Do
			
			CommonClientServer.SetDynamicListParameter(
				DynamicList,
				"DiscountMarkup",
				DiscountMarkup,
				True);
			
		EndDo;
		
	EndIf;
	
	UpdateUsageOfDiscountsMarkups(DiscountMarkup);
	
EndProcedure

#Region GeneratingQueryTextsForRedefinedLists

&AtServer
Function DynamicListQueryText1()
	
	RequestText = "SELECT
	|	MIN(T.Period) AS Period,
	|	T.DiscountMarkup AS DiscountMarkup
	|INTO Table
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source = &DefaultWarehouse) AS CrossSection
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups AS T
	|		ON (T.DiscountMarkup = CrossSection.DiscountMarkup)
	|			AND (T.Period > CrossSection.Period)
	|			AND (T.Source = &DefaultWarehouse)
	|			AND (T.Status <> CrossSection.Status)
	|
	|GROUP BY
	|	T.DiscountMarkup
	|;
	|SELECT &LoyaltyCardsTable;
	|SELECT &ModelAgreementsTable;
	|SELECT &IndividualAgreementsTable;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.DiscountMarkup AS DiscountMarkup,
	|	COUNT(T.Source) AS Count
	|INTO UseInWarehouses
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|			&CurrentDate,
	|			Source REFS Catalog.Warehouses
	|				AND Source <> VALUE(Catalog.Warehouses.EmptyRef)) AS T
	|WHERE
	|	T.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
	|
	|GROUP BY
	|	T.DiscountMarkup
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CatalogDiscountsMarkups.Description AS Description,
	|	CatalogDiscountsMarkups.IsFolder AS IsFolder,
	|	CASE
	|		WHEN CatalogDiscountsMarkups.IsFolder
	|			THEN CASE
	|					WHEN CatalogDiscountsMarkups.JointApplicationOption = VALUE(Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Max)
	|						THEN 8
	|					WHEN CatalogDiscountsMarkups.JointApplicationOption = VALUE(Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Min)
	|						THEN 16
	|					WHEN CatalogDiscountsMarkups.JointApplicationOption = VALUE(Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Addition)
	|						THEN 0
	|					WHEN CatalogDiscountsMarkups.JointApplicationOption = VALUE(Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Multiplication)
	|						THEN 4
	|					WHEN CatalogDiscountsMarkups.JointApplicationOption = VALUE(Enum.OptionsOfJointUsageOfDiscountsAndMarkups.Exclusion)
	|						THEN 12
	|				END + CASE
	|					WHEN CatalogDiscountsMarkups.DeletionMark
	|						THEN 3
	|					ELSE 0
	|				END
	|		ELSE CASE
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Percent)
	|					THEN CASE
	|							WHEN CatalogDiscountsMarkups.DiscountMarkupValue < 0
	|								THEN 32
	|							ELSE 28
	|						END
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Gift)
	|						OR CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Count)
	|					THEN 36
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Sum)
	|					THEN CASE
	|							WHEN CatalogDiscountsMarkups.DiscountMarkupValue < 0
	|								THEN 40
	|							ELSE 44
	|						END
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.RoundDocumentAmount)
	|					THEN CASE
	|							WHEN CatalogDiscountsMarkups.DiscountMarkupValue < 0
	|								THEN 40
	|							ELSE 44
	|						END
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.DiscountMarkupAsAmountForEachRow)
	|					THEN CASE
	|							WHEN CatalogDiscountsMarkups.DiscountMarkupValue < 0
	|								THEN 40
	|							ELSE 44
	|						END
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.PriceKind)
	|					THEN 48
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.Message)
	|					THEN 52
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding = VALUE(Enum.MethodsToProvideDiscountsMarkups.LoyaltyCard)
	|					THEN 52
	|				WHEN CatalogDiscountsMarkups.MethodsOfProviding REFS Catalog.AdditionalReportsAndDataProcessors
	|					THEN 56
	|			END + CASE
	|				WHEN CatalogDiscountsMarkups.DeletionMark
	|					THEN 3
	|				ELSE 0
	|			END
	|	END AS Picture,
	|	CatalogDiscountsMarkups.AddlOrderingAttribute AS AddlOrderingAttribute,
	|	CatalogDiscountsMarkups.Managed AS Managed,
	|	CatalogDiscountsMarkups.DeletionMark AS DeletionMark,
	|	CatalogDiscountsMarkups.Ref AS Ref,
	|	CatalogDiscountsMarkups.Parent AS Parent,
	|	CASE
	|		WHEN ISNULL(UseInWarehouses.Count, 0) > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ValidInWarehouses,
	|	ISNULL(UseInWarehouses.Count, 0) AS NumberOfWarehouses,
	|	&FieldLoyaltyCards,
	|	&TypicalFieldConventions,
	|	&IndividualFieldAgreements,
	|	CASE
	|		WHEN CatalogDiscountsMarkups.IsFolder
	|			THEN NULL
	|		ELSE ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Status, VALUE(Enum.DiscountValidityStatuses.NotValid))
	|	END AS Status,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Period, DATETIME(1, 1, 1)) AS StartDate,
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Period IS NULL
	|			THEN ISNULL(DATEADD(TheEffectOfDiscountsMarkupsASliceOfTheFirst.Period, DAY, -1), DATETIME(1, 1, 1))
	|		ELSE ISNULL(DATEADD(Table.Period, DAY, -1), DATETIME(1, 1, 1))
	|	END AS EndDate
	|FROM
	|	Catalog.DiscountsMarkups AS CatalogDiscountsMarkups
	|		{LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source = &DefaultWarehouse) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|			LEFT JOIN Table AS Table
	|			ON (Table.DiscountMarkup = TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup)
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheLast.DiscountMarkup = CatalogDiscountsMarkups.Ref)}
	|		{LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceFirst(&CurrentDate, Source = &DefaultWarehouse) AS TheEffectOfDiscountsMarkupsASliceOfTheFirst
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheFirst.DiscountMarkup = CatalogDiscountsMarkups.Ref)}
	|		{LEFT JOIN UseInWarehouses AS UseInWarehouses
	|		ON (UseInWarehouses.DiscountMarkup = CatalogDiscountsMarkups.Ref)}
	|		,&LoyaltyCardsConnection
	|		,&StandardConnectionAgreements
	|		,&IndividualAgreements_";
	
	AddTextInformationOnLoyaltyCardsToRequest(RequestText);
	AddTextAndInformationOnStandardAgreementsToRequest(RequestText);
	AddTextAndInformationOnIndividualAgreementsToRequest(RequestText);
	
	Return RequestText;
	
EndFunction

&AtServer
Procedure AddTextAndInformationOnIndividualAgreementsToRequest(RequestText)
	
	If UseCustomerTermsOfSales Then
		
		IndividualAgreementsTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.DiscountMarkup AS DiscountMarkup,
		|	COUNT(T.Source) AS Count
		|INTO UseInIndividualAgreements
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
		|			&CurrentDate,
		|			Source REFS Catalog.TermsOfSale
		|				AND CAST(Source AS Catalog.TermsOfSale).Standard_ = FALSE) AS T
		|WHERE
		|	T.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|
		|GROUP BY
		|	T.DiscountMarkup
		|;
		|";
		
		IndividualFieldAgreements = "
		|	CASE
		|		WHEN ISNULL(UseInIndividualAgreements.Count, 0) > 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ValidInIndividualAgreements,
		|	ISNULL(UseInIndividualAgreements.Count, 0) AS NumberOfIndividualAgreements,";
		
		IndividualAgreements_ = "
		|		{LEFT JOIN UseInIndividualAgreements AS UseInIndividualAgreements
		|		ON (UseInIndividualAgreements.DiscountMarkup = CatalogDiscountsMarkups.Ref)}";
		
	Else
		IndividualAgreementsTable    = "";
		IndividualAgreements_ = "";
		IndividualFieldAgreements       = "
		|	FALSE AS ValidInIndividualAgreements,
		|	0 AS NumberOfIndividualAgreements,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&IndividualFieldAgreements,", IndividualFieldAgreements);
	RequestText = StrReplace(RequestText, "SELECT &IndividualAgreementsTable;", IndividualAgreementsTable);
	RequestText = StrReplace(RequestText, ",&IndividualAgreements_", IndividualAgreements_);
	
EndProcedure

&AtServer
Procedure AddTextAndInformationOnStandardAgreementsToRequest(RequestText)
	
	If UseStandardTermsOfSalesWithCustomers Then
		
		ModelAgreementsTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.DiscountMarkup AS DiscountMarkup,
		|	COUNT(T.Source) AS Count
		|INTO UseInModelConventions
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
		|			&CurrentDate,
		|			Source REFS Catalog.TermsOfSale
		|				AND CAST(Source AS Catalog.TermsOfSale).Standard_) AS T
		|WHERE
		|	T.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|
		|GROUP BY
		|	T.DiscountMarkup
		|;
		|";
		
		TypicalFieldConventions = "
		|	CASE
		|		WHEN ISNULL(UseInModelConventions.Count, 0) > 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ValidInStandardAgreements,
		|	ISNULL(UseInModelConventions.Count, 0) AS NumberOfStandardAgreements,";
		
		StandardConnectionAgreements = "
		|		{LEFT JOIN UseInModelConventions AS UseInModelConventions
		|		ON (UseInModelConventions.DiscountMarkup = CatalogDiscountsMarkups.Ref)}";
		
		
	Else
		ModelAgreementsTable    = "";
		StandardConnectionAgreements = "";
		TypicalFieldConventions       = "
		|	FALSE AS ValidInStandardAgreements,
		|	0 AS NumberOfStandardAgreements,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&TypicalFieldConventions,", TypicalFieldConventions);
	RequestText = StrReplace(RequestText, "SELECT &ModelAgreementsTable;", ModelAgreementsTable);
	RequestText = StrReplace(RequestText, ",&StandardConnectionAgreements", StandardConnectionAgreements);
	
EndProcedure

&AtServer
Procedure AddTextInformationOnLoyaltyCardsToRequest(RequestText)
	
	If UseLoyaltyCards Then
		
		LoyaltyCardsTable = "
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	T.DiscountMarkup AS DiscountMarkup,
		|	COUNT(T.Source) AS Count
		|INTO UseInTypesOfLoyaltyCards
		|FROM
		|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(&CurrentDate, Source REFS Catalog.LoyaltyCardKinds) AS T
		|WHERE
		|	T.Status = VALUE(Enum.DiscountValidityStatuses.Valid)
		|
		|GROUP BY
		|	T.DiscountMarkup
		|;";
		
		FieldLoyaltyCards = "
		|	CASE
		|		WHEN ISNULL(UseInTypesOfLoyaltyCards.Count, 0) > 0
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ValidInLoyaltyCards,
		|	ISNULL(UseInTypesOfLoyaltyCards.Count, 0) AS NumberOfTypesOfLoyaltyCards,";
		
		LoyaltyCardsConnection = "
		|	{LEFT JOIN UseInTypesOfLoyaltyCards AS UseInTypesOfLoyaltyCards
		|	ON (UseInTypesOfLoyaltyCards.DiscountMarkup = CatalogDiscountsMarkups.Ref)}";
		
	Else
		LoyaltyCardsTable    = "";
		LoyaltyCardsConnection = "";
		FieldLoyaltyCards       = "
		|	FALSE AS ValidInLoyaltyCards,
		|	0 AS NumberOfTypesOfLoyaltyCards,
		|";
	EndIf;
	
	RequestText = StrReplace(RequestText, "&FieldLoyaltyCards,", FieldLoyaltyCards);
	RequestText = StrReplace(RequestText, "SELECT &LoyaltyCardsTable;", LoyaltyCardsTable);
	RequestText = StrReplace(RequestText, ",&LoyaltyCardsConnection", LoyaltyCardsConnection);
	
EndProcedure

&AtServer
Function DynamicListRequestTextIndividualAgreements()
	
	QueryText = 
	"SELECT
	|	MIN(T.Period) AS Period,
	|	T.Source AS Source
	|INTO Table
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|			&CurrentDate,
	|			DiscountMarkup = &DiscountMarkup
	|				AND Source REFS Catalog.TermsOfSale) AS CrossSection
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups AS T
	|		ON CrossSection.Source = T.Source
	|			AND (T.DiscountMarkup = &DiscountMarkup)
	|			AND (T.Period > CrossSection.Period)
	|			AND (T.Status <> CrossSection.Status)
	|
	|GROUP BY
	|	T.Source
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfSale.Ref AS Terms,
	|	TermsOfSale.Status AS AgreementStatus,
	|	TermsOfSale.Partner AS Partner,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Status, VALUE(Enum.DiscountValidityStatuses.NotValid)) AS Status,
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Status IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Period, DATETIME(1, 1, 1)) AS StartDate,
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Period IS NULL
	|			THEN ISNULL(DATEADD(TheEffectOfDiscountsMarkupsASliceOfTheFirst.Period, DAY, -1), DATETIME(1, 1, 1))
	|		ELSE ISNULL(DATEADD(Table.Period, DAY, -1), DATETIME(1, 1, 1))
	|	END AS EndDate
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|				&CurrentDate,
	|				DiscountMarkup = &DiscountMarkup
	|					AND Source REFS Catalog.TermsOfSale) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheLast.Source = TermsOfSale.Ref)
	|		LEFT JOIN Table AS Table
	|		ON (Table.Source = TermsOfSale.Ref)
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceFirst(
	|				&CurrentDate,
	|				DiscountMarkup = &DiscountMarkup
	|					AND Source REFS Catalog.TermsOfSale) AS TheEffectOfDiscountsMarkupsASliceOfTheFirst
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheFirst.Source = TermsOfSale.Ref)
	|WHERE
	|	NOT TermsOfSale.Standard_";
	
	Return QueryText;
	
EndFunction

&AtServer
Function DynamicListRequestTextStandardConventions()
	
	QueryText = 
	"SELECT
	|	MIN(T.Period) AS Period,
	|	T.Source AS Source
	|INTO Table
	|FROM
	|	InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|			&CurrentDate,
	|			DiscountMarkup = &DiscountMarkup
	|				AND Source REFS Catalog.TermsOfSale) AS CrossSection
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups AS T
	|		ON CrossSection.Source = T.Source
	|			AND (T.DiscountMarkup = &DiscountMarkup)
	|			AND (T.Period > CrossSection.Period)
	|			AND (T.Status <> CrossSection.Status)
	|
	|GROUP BY
	|	T.Source
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TermsOfSale.Ref AS Terms,
	|	TermsOfSale.Ref.Status AS AgreementStatus,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Status, VALUE(Enum.DiscountValidityStatuses.NotValid)) AS Status,
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Status IS NULL
	|			THEN FALSE
	|		ELSE TRUE
	|	END AS Use,
	|	ISNULL(TheEffectOfDiscountsMarkupsASliceOfTheLast.Period, DATETIME(1, 1, 1)) AS StartDate,
	|	CASE
	|		WHEN TheEffectOfDiscountsMarkupsASliceOfTheLast.Period IS NULL
	|			THEN ISNULL(DATEADD(TheEffectOfDiscountsMarkupsASliceOfTheFirst.Period, DAY, -1), DATETIME(1, 1, 1))
	|		ELSE ISNULL(DATEADD(Table.Period, DAY, -1), DATETIME(1, 1, 1))
	|	END AS EndDate
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceLast(
	|				&CurrentDate,
	|				DiscountMarkup = &DiscountMarkup
	|					AND Source REFS Catalog.TermsOfSale) AS TheEffectOfDiscountsMarkupsASliceOfTheLast
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheLast.Source = TermsOfSale.Ref)
	|		LEFT JOIN Table AS Table
	|		ON (Table.Source = TermsOfSale.Ref)
	|		LEFT JOIN InformationRegister.ValidityOfDiscountsMarkups.SliceFirst(
	|				&CurrentDate,
	|				DiscountMarkup = &DiscountMarkup
	|					AND Source REFS Catalog.TermsOfSale) AS TheEffectOfDiscountsMarkupsASliceOfTheFirst
	|		ON (TheEffectOfDiscountsMarkupsASliceOfTheFirst.Source = TermsOfSale.Ref)
	|WHERE
	|	TermsOfSale.Standard_";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region OverridingDynamicLists

&AtServer
Procedure OverridePropertiesOfDynamicLists()
	
	OverridePropertiesOfMainList();
	OverridePropertiesOfUseListInTypicalCustomerAgreements();
	OverridePropertiesOfUsageListInIndividualCustomerAgreements();
	
EndProcedure

&AtServer
Procedure OverridePropertiesOfMainList()
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = DynamicListQueryText1();
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
EndProcedure

&AtServer
Procedure OverridePropertiesOfUseListInTypicalCustomerAgreements()
	
	If UseStandardTermsOfSalesWithCustomers Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText                 = DynamicListRequestTextStandardConventions();
		ListProperties.MainTable              = "Catalog.TermsOfSale";
		ListProperties.DynamicDataRead = True;
		Common.SetDynamicListProperties(Items.UseInStandardAgreementsWithCustomers, ListProperties);
	EndIf;
	
EndProcedure

&AtServer
Procedure OverridePropertiesOfUsageListInIndividualCustomerAgreements()
	
	If UseCustomerTermsOfSales Then
		ListProperties = Common.DynamicListPropertiesStructure();
		ListProperties.QueryText                 = DynamicListRequestTextIndividualAgreements();
		ListProperties.MainTable              = "Catalog.TermsOfSale";
		ListProperties.DynamicDataRead = True;
		Common.SetDynamicListProperties(Items.UseInIndividualAgreementsWithCustomers, ListProperties);
	EndIf;
	
EndProcedure

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
	If Item.Name = "sh_ShamsiInput_F_SliceDate" Then
		FilterSliceDateOnChange(Items.FilterSliceDate);
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
