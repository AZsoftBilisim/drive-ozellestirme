
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	QuickFilterStructure = Undefined;
	Parameters.Property("QuickFilterStructure", QuickFilterStructure);
	
	ListSelectionsClientServer.SelectionByListValueWhenCreatedOnServer(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure);
	
	UpdateOrdersOnServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	ListSelectionsClientServer.SelectionByListValueWhenLoadingFromSettings(List, "EmployeeResponsible", EmployeeResponsible, QuickFilterStructure, Settings);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region EventHandlers

&AtClient
Procedure EmployeeResponsibleOnChange(Item)
	
	CommonClientServer.SetDynamicListFilterItem(List, "EmployeeResponsible", EmployeeResponsible, DataCompositionComparisonType.Equal,, ValueIsFilled(EmployeeResponsible));
	
EndProcedure

&AtClient
Procedure RequestPeriodOnChange(Item)
	
	ApplyOrderSelection();
	
EndProcedure

&AtClient
Procedure SelectionOfOrdersClassWhenChanging(Item)
	
	ApplyOrderSelection();
	
EndProcedure

&AtClient
Procedure SelectionOfOrdersOperatingDivisionOnChange(Item)
	
	ApplyOrderSelection();
	
EndProcedure

&AtClient
Procedure ReferencesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.ReferencesPresentation Then
		ShowValue(Undefined, References.FindByID(RowSelected).Asset);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure CreateARegistrationOfDevelopments(Command)
	
	CreateRegistrationOfDevelopmentsOnListOfOrders();
	
EndProcedure

&AtClient
Procedure RefreshOrders(Command)
	UpdateOrdersOnServer();
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Items.List);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesPresentation.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesRunningTimeValue.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesDaysOverdue_3.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesLastRegistrationDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesNextRegistrationDate.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesClass.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesOperatingBusinessUnit.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesPeriodicity.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ReferencesFrequencyKind.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("References.Overdue");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.OverdueDataColor);
	
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "List.Date", Items.Date.Name);
	
EndProcedure 

&AtClient
Procedure CreateRegistrationOfDevelopmentsOnListOfOrders()
	
	CurrentData = Items.References.CurrentData;
	If CurrentData = Undefined Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
							|ru = 'Команда не может быть выполнена для указанного объекта';
							|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato';
							|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
							|tr = 'Komut belirtilen nesne için uygulanamaz'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	EndIf;
	
	OrderStructureFields = "Asset, RunningTimeValue";
	
	If Items.References.SelectedRows.Count() = 0 Then
		
		WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
							|ru = 'Команда не может быть выполнена для указанного объекта';
							|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
							|it = 'Il comando non può essere eseguito per l''oggetto indicato';
							|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
							|tr = 'Komut belirtilen nesne için uygulanamaz'");
		ShowMessageBox(Undefined, WarningText);
		Return;
		
	Else
		
		ReferenceArray = New Array();
		
		For Each String In Items.References.SelectedRows Do
		
			If TypeOf(String) = Type("DynamicListGroupRow") Then
				Continue;
			EndIf;
			
			OrderStructure_ = New Structure(OrderStructureFields);
			FillPropertyValues(OrderStructure_, References.FindByID(String));
			ReferenceArray.Add(OrderStructure_);
			
		EndDo;
		
		If ReferenceArray.Count() = 0 Then
			
			WarningText = NStr("vi = 'Không thể thực hiện lệnh đối với đối tượng được chọn';
								|ru = 'Команда не может быть выполнена для указанного объекта';
								|en = 'Cannot execute the command for the specified object'; fa = 'Cannot execute the command for the specified object';
								|it = 'Il comando non può essere eseguito per l''oggetto indicato';
								|pl = 'Polecenie nie może zostać wykonane dla wskazanego obiektu';
								|tr = 'Komut belirtilen nesne için uygulanamaz'");
			ShowMessageBox(Undefined, WarningText);
			Return;
			
		EndIf;
		
		ClearMessages();
		
		BasisParameters = New Structure();
		BasisParameters.Insert("DocumentBasis", ReferenceArray);
		
		OpenForm(
			"Document.AssetActivityRecord.Form.DocumentForm",
			New Structure("Basis", BasisParameters));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ApplyOrderSelection()
	
	FilterStructure1 = New Structure;
	
	If ValueIsFilled(RequestPeriod) Then
		If RequestPeriod = 1 Then
			FilterStructure1.Insert("Overdue", True);
		ElsIf RequestPeriod = 2 Then
			FilterStructure1.Insert("ThisDay", True);
		ElsIf RequestPeriod = 3 Then
			FilterStructure1.Insert("ThisWeek", True);
		ElsIf RequestPeriod = 4 Then
			FilterStructure1.Insert("ThisMonth", True);
		EndIf;
	EndIf;
	
	If ValueIsFilled(OrderSelectionClass) Then
		FilterStructure1.Insert("Class", OrderSelectionClass);
	EndIf;
	
	If ValueIsFilled(SelectionOfOrdersOperatingDivision) Then
		FilterStructure1.Insert("OperatingBusinessUnit", SelectionOfOrdersOperatingDivision);
	EndIf;
	
	Items.References.RowFilter = New FixedStructure(FilterStructure1);
	
EndProcedure

&AtServer
Procedure UpdateOrdersOnServer()
	
	Query = New Query(OrderRequestText_());
	
	MethodsOfDepreciation = New Array;
	MethodsOfDepreciation.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction);
	MethodsOfDepreciation.Add(Enums.AccrualMethodOfFixedAssetsDepreciation.ByUniformDepreciationRatesPer1000KmOfMileage);
	
	Query.SetParameter("MethodsOfDepreciation", MethodsOfDepreciation);
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("UseRMManagement", GetFunctionalOption("UseRMManagement"));
	Query.SetParameter("UseSubAssets", GetFunctionalOption("UseSubAssets"));
	Query.SetParameter("VNAManagementIsUsed_2_4", NonCurrentAssets.VNAManagementIsUsed_2_4());
	
	SetPrivilegedMode(True);
	References.Load(Query.Execute().Unload());
	SetPrivilegedMode(False);
	
EndProcedure

&AtServer
Function OrderRequestText_()
	
	QueriesArray = New Array;
	
	QueryText = RunningTimeRegistrationLocalization.QueryTextLocalIndicators();
	
	If QueryText = Undefined Then
		
		QueryText =
		"SELECT
		|	AccountingProcedureForOSBU.FixedAsset AS FixedAsset
		|INTO ListByOperatingTime
		|FROM
		|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(&CurrentDate, CorrectionDate = DATETIME(1,1,1)) AS AccountingProcedureForOSBU
		|WHERE
		|	AccountingProcedureForOSBU.DepreciationMethod IN(&MethodsOfDepreciation)
		|	AND &VNAManagementIsUsed_2_4
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsAccountingProcedureManagementAccounting.FixedAsset AS FixedAsset
		|INTO FAAcceptedForAccounting
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedureManagementAccounting.SliceLast(
		|			&CurrentDate,
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN
		|					(SELECT
		|						ListByOperatingTime.FixedAsset
		|					FROM
		|						ListByOperatingTime)) AS FixedAssetsAccountingProcedureManagementAccounting
		|WHERE
		|	FixedAssetsAccountingProcedureManagementAccounting.State = VALUE(Enum.FixedAssetsStates.Recognized_)
		|	AND CASE
		|			WHEN &UseRMManagement
		|				THEN FixedAssetsAccountingProcedureManagementAccounting.FixedAsset.Status IN (VALUE(Enum.AssetStatuses.InOperation))
		|			ELSE TRUE
		|		END
		|
		|INDEX BY
		|	FixedAsset
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	FixedAssetsAccountingProcedure.FixedAsset AS Asset,
		|	PRESENTATION(FixedAssetsAccountingProcedure.FixedAsset) AS Presentation,
		|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue,
		|	1 AS Periodicity,
		|	1 AS FrequencyKind
		|INTO LocalIndicators
		|FROM
		|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
		|			&CurrentDate,
		|			CorrectionDate = DATETIME(1,1,1)
		|				AND FixedAsset IN
		|					(SELECT
		|						FAAcceptedForAccounting.FixedAsset
		|					FROM
		|						FAAcceptedForAccounting)) AS FixedAssetsAccountingProcedure
		|WHERE
		|	FixedAssetsAccountingProcedure.RunningTimeValue <> VALUE(Catalog.RunningTimeValues.EmptyRef)";
		
	EndIf; 
	
	QueriesArray.Add(QueryText);

	QueryText = "
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Objects.Ref AS Asset,
	|	PRESENTATION(Objects.Ref) AS Presentation,
	|	PerformanceIndicatorsOfClass.RunningTimeValue AS RunningTimeValue,
	|	PerformanceIndicatorsOfClass.FrequencyOfRegistrationDays AS Periodicity,
	|	0 AS FrequencyKind,
	|	PerformanceIndicatorsOfClass.RegisterBySource AS RegisterBySource
	|INTO RemIndicators
	|FROM
	|	Catalog.Assets AS Objects
	|		INNER JOIN Catalog.MaintenanceSchemes.RunningTimeValues AS PerformanceIndicatorsOfClass
	|		ON Objects.Class = PerformanceIndicatorsOfClass.Ref
	|WHERE
	|	PerformanceIndicatorsOfClass.FrequencyOfRegistrationDays <> 0
	|	AND Objects.Status IN (VALUE(Enum.AssetStatuses.InOperation))
	|	AND &UseRMManagement
	|
	|UNION ALL
	|
	|SELECT
	|	Nodes.Ref,
	|	Nodes.Belonging,
	|	PerformanceIndicatorsOfClass.RunningTimeValue,
	|	PerformanceIndicatorsOfClass.FrequencyOfRegistrationDays,
	|	0,
	|	PerformanceIndicatorsOfClass.RegisterBySource
	|FROM
	|	Catalog.SubAssets AS Nodes
	|		INNER JOIN Catalog.MaintenanceSchemes.RunningTimeValues AS PerformanceIndicatorsOfClass
	|		ON Nodes.Class = PerformanceIndicatorsOfClass.Ref
	|WHERE
	|	PerformanceIndicatorsOfClass.FrequencyOfRegistrationDays <> 0
	|	AND Nodes.Owner <> VALUE(Catalog.Assets.EmptyRef)
	|	AND Nodes.Status IN (VALUE(Enum.AssetStatuses.InOperation))
	|	AND &UseSubAssets
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	LocalIndicators.Asset AS Asset,
	|	LocalIndicators.Presentation AS Presentation,
	|	LocalIndicators.RunningTimeValue AS RunningTimeValue,
	|	LocalIndicators.Periodicity AS FrequencyOfRegistrationDays,
	|	LocalIndicators.FrequencyKind AS FrequencyKind
	|INTO Indicators
	|FROM
	|	LocalIndicators AS LocalIndicators
	|		LEFT JOIN RemIndicators AS RemIndicators
	|		ON LocalIndicators.Asset = RemIndicators.Asset
	|			AND LocalIndicators.RunningTimeValue = RemIndicators.RunningTimeValue
	|WHERE
	|	RemIndicators.Asset IS NULL 
	|
	|UNION ALL
	|
	|SELECT
	|	RemIndicators.Asset,
	|	RemIndicators.Presentation,
	|	RemIndicators.RunningTimeValue,
	|	RemIndicators.Periodicity,
	|	RemIndicators.FrequencyKind
	|FROM
	|	RemIndicators AS RemIndicators
	|WHERE
	|	NOT RemIndicators.RegisterBySource
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Indicators.Asset,
	|	Indicators.Presentation,
	|	Indicators.RunningTimeValue,
	|	ISNULL(DevelopmentsCut.Period, UNDEFINED) AS LastRegistrationDate,
	|	CASE
	|		WHEN DevelopmentsCut.Period IS NULL 
	|			THEN &CurrentDate
	|		WHEN Indicators.FrequencyKind = 1
	|			THEN DATEADD(DevelopmentsCut.Period, MONTH, Indicators.FrequencyOfRegistrationDays)
	|		ELSE DATEADD(DevelopmentsCut.Period, DAY, Indicators.FrequencyOfRegistrationDays)
	|	END AS NextRegistrationDate,
	|	CASE
	|		WHEN DevelopmentsCut.Period IS NULL 
	|			THEN 0
	|		WHEN Indicators.FrequencyKind = 1
	|			THEN DATEDIFF(DATEADD(DevelopmentsCut.Period, MONTH, Indicators.FrequencyOfRegistrationDays), &CurrentDate, DAY)
	|		ELSE DATEDIFF(DATEADD(DevelopmentsCut.Period, DAY, Indicators.FrequencyOfRegistrationDays), &CurrentDate, DAY)
	|	END AS DaysOverdue_3,
	|	Indicators.Asset.Class AS Class,
	|	Indicators.Asset.OperatingBusinessUnit AS OperatingBusinessUnit,
	|	Indicators.FrequencyOfRegistrationDays AS Periodicity,
	|	Indicators.FrequencyKind
	|INTO References
	|FROM
	|	Indicators AS Indicators
	|		LEFT JOIN InformationRegister.AssetActivityRecords.SliceLast(
	|				&CurrentDate,
	|				(Asset, RunningTimeValue) IN
	|					(SELECT
	|						Indicators.Asset,
	|						Indicators.RunningTimeValue
	|					FROM
	|						Indicators AS Indicators)) AS DevelopmentsCut
	|		ON Indicators.Asset = DevelopmentsCut.Asset
	|			AND Indicators.RunningTimeValue = DevelopmentsCut.RunningTimeValue
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.Asset,
	|	References.Presentation,
	|	References.RunningTimeValue,
	|	References.LastRegistrationDate,
	|	References.NextRegistrationDate,
	|	References.DaysOverdue_3,
	|	References.Class,
	|	References.OperatingBusinessUnit,
	|	References.Periodicity,
	|	References.FrequencyKind,
	|	CASE
	|		WHEN References.DaysOverdue_3 > 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Overdue,
	|	CASE
	|		WHEN BEGINOFPERIOD(References.NextRegistrationDate, DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisDay,
	|	CASE
	|		WHEN BEGINOFPERIOD(References.NextRegistrationDate, WEEK) = BEGINOFPERIOD(&CurrentDate, WEEK)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisWeek,
	|	CASE
	|		WHEN BEGINOFPERIOD(References.NextRegistrationDate, MONTH) = BEGINOFPERIOD(&CurrentDate, MONTH)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisMonth
	|FROM
	|	References AS References";
	
	QueriesArray.Add(QueryText);
	
	QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
	
	Return QueryText;
	
EndFunction

#EndRegion
