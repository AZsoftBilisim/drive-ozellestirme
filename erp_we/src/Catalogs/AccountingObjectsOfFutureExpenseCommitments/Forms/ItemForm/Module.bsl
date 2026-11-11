
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(Object.ReserveKind);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetParametersForSelectingExpenseAnalytics();
	
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	OnReadCreateAtServer();
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(Object.ReserveKind);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	For Each String In Object.UseReserve Do
		FillInReserveUsageDetails(String.GetID());
	EndDo;
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	If Cancel Then
		Return;
	EndIf;
	
	RefToNew = Undefined;
	For Each String In Object.UseReserve Do
		
		RowIndex = Object.UseReserve.IndexOf(String);
		CurObjectString = CurrentObject.UseReserve.Get(RowIndex);
		If String.DimensionProvisionObject Then
			If CurrentObject.IsNew() Then
				If RefToNew = Undefined Then
					NewRef = Catalogs.AccountingObjectsOfFutureExpenseCommitments.GetRef();
					CurrentObject.SetNewObjectRef(NewRef);
					RefToNew = CurrentObject.GetNewObjectRef();
				EndIf;
				CurObjectString.DimensionOfExpenses = RefToNew;		
			ElsIf CurObjectString.DimensionOfExpenses <> CurrentObject.Ref Then
				CurObjectString.DimensionOfExpenses = CurrentObject.Ref;
			EndIf;
		EndIf;
		CurObjectString.AnyExpenseDimension = Not String.ExpenditureDimensionIsSpecified And Not String.DimensionProvisionObject;
		
	EndDo;
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	Errors = Undefined;
	
	If Object.BeginOfPeriod > Object.EndOfPeriod And ValueIsFilled(Object.EndOfPeriod) Then
		CommonClientServer.AddUserError(
			Errors,
			"Object.EndOfPeriod",
			NStr("vi = 'Ngày hết hạn dự phòng ít hơn ngày bắt đầu';
				|ru = 'Дата окончания действия резерва меньше даты начала';
				|en = 'Reserve expiration date is less than the start date'; fa = 'Reserve expiration date is less than the start date';
				|it = 'La data di termine della riserva è inferiore alla data di inizio';
				|pl = 'Termin zakończenia ważności rezerwy nie może być wcześniejszy od daty rozpoczęcia';
				|tr = 'Yedeğin bitiş tarihi, başlangıç ​​tarihinden daha az'"),
			Undefined);
	EndIf;
	
	If Not ValueIsFilled(Object.BusinessUnitAccruals) Then
		// Additional check on the need to fill in the division for production items
		DistributionDetails = Common.ObjectAttributesValues(Object.ExpenseItemAccruals,
			"CostAllocationOptionLocal,CostAllocationOptionManag", False, Common.DefaultLanguageCode());
		
		ProductionDistributionOptions = ProductionServerCached.GetProductionDistributionOptions();
		If ProductionDistributionOptions.Find(DistributionDetails.CostAllocationOptionLocal) <> Undefined
			Or ProductionDistributionOptions.Find(DistributionDetails.CostAllocationOptionManag) <> Undefined Then
			
			ErrorsMessage = NStr("vi = 'Đối với các dạng chi phí sản xuất ""%1"" cần chỉ ra bộ phận.';
								|ru = 'Для производственной статьи расходов ""%1"" требуется указать подразделение.';
								|en = 'Please specify business unit for the production expense item ""%1"".'; fa = 'Please specify business unit for the production expense item ""%1"".';
								|it = 'Per la voce ""%1"" relativa alle spese di produzione è necessario indicare il reparto.';
								|pl = 'Dla pozycji produkcyjnej rozchodów ""%1"" wymagane jest wskazanie działu.';
								|tr = '""%1"" üretim gider kalemi için departman belirtilmesi gerekir.'");
			ErrorsMessage = StrTemplate(ErrorsMessage, Object.ExpenseItemAccruals);
			CommonClientServer.AddUserError(
			Errors,
			"Object.BusinessUnitAccruals",
			ErrorsMessage,
			Undefined);
			
		EndIf;
		
	EndIf;
	
	If Errors <> Undefined Then
		CommonClientServer.ReportErrorsToUser(Errors, Cancel);
	EndIf;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExpenseItemAccrualsOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure
	
&AtClient
Procedure IncomeItemOfWriteOffOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure ExpenseItemAccrualsStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure IncomeItemOfWriteOffStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionAccrualsStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionAccrualsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure ExpensesDimensionAccrualsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties	
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure ReserveKindOnChange(Item)
	TypeOfReservesWhenChangingOnServer();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure UseReserveOnStartEdit(Item, NewRow, Copy)
	CurrentData = Items.UseReserve.CurrentData;
	IncomeAndExpensesClientServer.WhenAddingRowToTable(ThisObject, CurrentData, "Object.UseReserve");
EndProcedure

&AtClient
Procedure UseReserveExpenseItemOnChange(Item)
	
	FillInReserveUsageDetails(Items.UseReserve.CurrentRow, True);
	
EndProcedure

&AtClient
Procedure UseReserveExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure UseReserveDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure UseReserveDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

&AtClient
Procedure UseReserveDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

#Region StandardSubsystems

// StandardSubsystems.Properties

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ObjectAttributesLockClient.AllowObjectAttributeEdit(ThisObject);
	
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure OnReadCreateAtServer()
	
	For Each String In Object.UseReserve Do
		FillInReserveUsageDetails(String.GetID());
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInReserveUsageDetails(RowID, WhenChangingArticle = False)
	
	If WhenChangingArticle Then
		IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.UseReserveExpenseItem);
	EndIf;

	String = Object.UseReserve.FindByID(RowID);
	
	DimensionProvisionObject = False;
	ExpenditureDimensionIsSpecified = ?(WhenChangingArticle, String.ExpenditureDimensionIsSpecified, Not String.AnyExpenseDimension);
	
	If ValueIsFilled(String.ExpenseItem) Then
		DetailsOfExpenditureItem = Common.ObjectAttributesValues(String.ExpenseItem, "ValueType");
		If DetailsOfExpenditureItem.ValueType.ContainsType(Type("CatalogRef.AccountingObjectsOfFutureExpenseCommitments")) Then
			DimensionProvisionObject = True;
			ExpenditureDimensionIsSpecified = True;
		EndIf;
	EndIf;
	
	String.DimensionProvisionObject = DimensionProvisionObject;
	String.ExpenditureDimensionIsSpecified = ExpenditureDimensionIsSpecified;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.UseReserveDimensionOfExpenses.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.DimensionProvisionObject", False);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.ExpenditureDimensionIsSpecified", True);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.DimensionOfExpenses", Undefined, DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("ReadOnly", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.UseReserveDimensionOfExpenses.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.ExpenditureDimensionIsSpecified", False);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.DimensionProvisionObject", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<mọi chỉ số>';
													|ru = '<любая аналитика>';
													|en = '<any dimension>'; fa = '<any dimension>';
													|it = '<qualsiasi analisi>';
													|pl = '<dowolna analityka>';
													|tr = '<herhangi boyut>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.UseReserveDimensionOfExpenses.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.ExpenditureDimensionIsSpecified", False);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	//
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.UseReserveDimensionOfExpenses.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.DimensionProvisionObject", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<đối tượng hạch toán dự phòng>';
													|ru = '<этот объект учета резервов>';
													|en = '<this provision object>'; fa = '<this provision object>';
													|it = '<questo è un oggetto di contabilità delle riserve>';
													|pl = '<ten obiekt ewidencji rezerw>';
													|tr = '<bu nesne yedek muhasebesidir>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.UseReserveExpenditureDimensionIsSpecified.Name);
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.UseReserve.DimensionProvisionObject", True);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
EndProcedure

#Region StandardSubsystemsProperties

// StandardSubsystems.Properties 

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

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

&AtServer
Procedure TypeOfReservesWhenChangingOnServer()
	
	ItemsAndDimensionsSelectionParameters = Catalogs.AccountingObjectsOfFutureExpenseCommitments.ItemsAndDimensionsSelectionParameters(Object.ReserveKind);
	DeleteSelectionBasedOnTypeOfValueOfExpenseItemObjectsOfOperation();
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	SetParametersForSelectingExpenseAnalytics();
	ClearAnalyticsAndExpenseItemsIfSelectionParametersDoNotMatch();
	
EndProcedure

&AtServer
Procedure ClearAnalyticsAndExpenseItemsIfSelectionParametersDoNotMatch()

	If Not ValueIsFilled(Object.ReserveKind) Then
		Return;
	EndIf;
		
	ReserveType = Common.ObjectAttributeValue(Object.ReserveKind, "ReserveType");
			
	If ReserveType <> Enums.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities Then
		Return;
	EndIf;
	
	If ValueIsFilled(Object.ExpenseItemAccruals) Then
		ExpensesOnAssets = Common.ObjectAttributeValue(Object.ExpenseItemAccruals,
			"ExpensesOnAssets");		
			
		If Not ExpensesOnAssets Then
			Object.ExpenseItemAccruals = ChartsOfCharacteristicTypes.ExpenseItems.EmptyRef();
			Object.ExpensesDimensionAccruals = Undefined;
			
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemAccruals);
		EndIf; 
					
	EndIf;
	
EndProcedure

&AtServer
Procedure DeleteSelectionBasedOnTypeOfValueOfExpenseItemObjectsOfOperation()
	
	If ValueIsFilled(Object.ReserveKind) Then
		ReserveType = Common.ObjectAttributeValue(Object.ReserveKind, "ReserveType");
			
		If ReserveType = Enums.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities Then
			Return;
		EndIf;
	EndIf;
	
	DeleteSelection = False;
	
	FormItem = Items.ExpenseItemAccruals;
	NameOfSelectionOfExpenditureItemsObjectsOfOperation = "Filter.ExpensesOnAssets";
	
	NewSelectionOptions = New Array;
	ArticleItemSelectionOptions = FormItem.ChoiceParameters; 
	For Each CurrentParameter In ArticleItemSelectionOptions Do
		If CurrentParameter.Name = NameOfSelectionOfExpenditureItemsObjectsOfOperation Then
			DeleteSelection = True;	
		Else
			NewSelectionOptions.Add(CurrentParameter);			
		EndIf;
	EndDo;

	If DeleteSelection Then
		FormItem.ChoiceParameters = New FixedArray(NewSelectionOptions);		
	EndIf;
		
EndProcedure

&AtServer
Procedure SetParametersForSelectingExpenseAnalytics()
	
	ParametersArray = New Array;
	ReserveType = Common.ObjectAttributeValue(Object.ReserveKind, "ReserveType");
	If ReserveType = Enums.TypesOfProvisionsAndContingentLiabilities.ResidualLiabilities Then
		NewParameter1 = New ChoiceParameter("Filter.ConsiderResidualLiabilityValue", True);
		ParametersArray.Add(NewParameter1);
	EndIf;
	CostSelectionParameters = New FixedArray(ParametersArray);
	
	Items.ExpensesDimensionAccruals.ChoiceParameters = CostSelectionParameters;
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
