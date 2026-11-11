#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	OptionOfAssignedAccountingOfGoods = Enums.OptionsOfAssignedAccountingOfGoods.NotKept;

	If IsNew() Then
		Status = Enums.BusinessUnitCompanyStatuses.Valid;
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	OptionNames = New Array;
	OptionNames.Add("UseOperationManagement");
	OptionNames.Add("UseManufacturingExecutionSystem");
	OptionNames.Add("UseShiftTasks");
	
	
	ValueOfOptionsBeforeChange    = New Structure;
	ValueOfOptionsAfterChange = New Structure;
	
	For Each OptionName1 In OptionNames Do
		ValueOfOptionsAfterChange.Insert(OptionName1, ThisObject[OptionName1]);
	EndDo;
	If IsNew() Then
		
		CurrentRef = Catalogs.BusinessStructure.GetRef();
		SetNewObjectRef(CurrentRef);
		ChangedAttribute = ProductionBusinessUnit;
	Else
		Attributes = New Structure;
		Attributes.Insert("ProductionBusinessUnit", "ProductionBusinessUnit");
		Attributes.Insert("OperationManagementMethod", "OperationManagementMethod");
		
		For Each OptionName1 In OptionNames Do
			Attributes.Insert(OptionName1);
		EndDo;
		
		DetailsBeforeRecording = Common.ObjectAttributesValues(Ref, Attributes);
		
		ChangedAttribute = DetailsBeforeRecording.ProductionBusinessUnit
			<> ProductionBusinessUnit;
			
		For Each OptionName1 In OptionNames Do
			ValueOfOptionsBeforeChange.Insert(OptionName1, DetailsBeforeRecording[OptionName1]);
		EndDo;
		

		CurrentRef = Ref;
		
	EndIf;
	
	AdditionalProperties.Insert("Ref", CurrentRef);
	AdditionalProperties.Insert("ChangedAttribute", ChangedAttribute);
	AdditionalProperties.Insert("CalculateProductionDuration",
		ItIsNecessaryToCalculateDurationOfProduction(Cancel));
	AdditionalProperties.Insert("ValueOfOptionsBeforeChange",    ValueOfOptionsBeforeChange);
	AdditionalProperties.Insert("ValueOfOptionsAfterChange", ValueOfOptionsAfterChange);
	// Installing the props of the props of ordering
	If Not Cancel And AddlOrderingAttribute = 0 Then
		
		SetPrivilegedMode(True);
		
		Query = New Query(
		"SELECT TOP 1
		|	Table.AddlOrderingAttribute AS AddlOrderingAttribute
		|FROM
		|	Catalog.BusinessStructure AS Table
		|
		|ORDER BY
		|	AddlOrderingAttribute DESC");
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		AddlOrderingAttribute = ?(Not ValueIsFilled(Selection.AddlOrderingAttribute), 1, Selection.AddlOrderingAttribute + 1);
		
	EndIf;
	
	If Status = Enums.BusinessUnitCompanyStatuses.NotValid And Not IsNew() Then
		Query = New Query;
		Query.SetParameter("Ref", CurrentRef);
		Query.Text =
		"SELECT TOP 1
		|	BusinessStructure.Ref AS Ref
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|WHERE
		|	BusinessStructure.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
		|	AND BusinessStructure.Parent = &Ref";
		
		If Not Query.Execute().IsEmpty() Then 
			Common.MessageToUser(
				NStr("vi = 'Đang có các bộ phận trực thuộc còn hiệu lực. Không thể thiết lập trạng thái ""không hiệu lực"".';
					|ru = 'Существуют подчиненные действующие подразделения. Статус ""не действует"" не может быть установлен.';
					|en = 'There are subordinate active business units. Cannot set the ""Inactive"" status.'; fa = 'There are subordinate active business units. Cannot set the ""Inactive"" status.';
					|it = 'Существуют подчиненные действующие подразделения. Статус ""не действует"" не может быть установлен.';
					|pl = 'There are subordinate active business units. Cannot set the ""Inactive"" status.';
					|tr = 'Aktif departmanlar mevcuttur. ""Aktif değil"" durumu ayarlanamaz.'"),
				,
				"Status",
				,
				Cancel);
		EndIf;     
	EndIf;
	If ValueIsFilled(Parent) 
		And Status = Enums.BusinessUnitCompanyStatuses.Valid
		And Common.ObjectAttributeValue(Parent, "Status") = Enums.BusinessUnitCompanyStatuses.NotValid Then

		Common.MessageToUser(
			NStr("vi = 'Tại bộ phận lớp trên đã thiết lập trạng thái ""không hiệu lực"". Không thể thiết lập trạng thái ""có hiệu lực"".';
				|ru = 'У родительского подразделения установлен статус ""не действует"". Статус ""действует"" не может быть установлен.';
				|en = 'The parent business unit has the ""Inactive"" status. Cannot set the ""Active"" status.'; fa = 'The parent business unit has the ""Inactive"" status. Cannot set the ""Active"" status.';
				|it = 'У родительского подразделения установлен статус ""не действует"". Статус ""действует"" не может быть установлен.';
				|pl = 'The parent business unit has the ""Inactive"" status. Cannot set the ""Active"" status.';
				|tr = 'Departmanın durumu ""Aktif değil"" olarak ayarlandı. ""Aktif"" durumu ayarlanamaz.'"),
			,
			"Status",
			,
			Cancel);
	EndIf;
	AddWHDivisionToAccountForSeriesOfProductTypes(AdditionalProperties.Ref);
	UpdateUsageFlag();
	TMCommonUse.PrepareDataForKeySynchronization(ThisObject, KeySynchronizationSettings());	
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	ServiceConstants_ = New Structure;
	
	ValueOfOptionsBeforeChange    = AdditionalProperties.ValueOfOptionsBeforeChange;
	ValueOfOptionsAfterChange = AdditionalProperties.ValueOfOptionsAfterChange;
	
	If ValueIsFilled(ValueOfOptionsBeforeChange) Then
		
		
		If ValueOfOptionsAfterChange.UseOperationManagement <>
				ValueOfOptionsBeforeChange.UseOperationManagement
		 Or ValueOfOptionsAfterChange.UseManufacturingExecutionSystem <>
		 		ValueOfOptionsBeforeChange.UseManufacturingExecutionSystem Then
			
			ServiceConstants_.Insert(
				"UseOperationManagement",
				ValueOfOptionsAfterChange.UseOperationManagement
					And Not ValueOfOptionsAfterChange.UseManufacturingExecutionSystem);
			
			ServiceConstants_.Insert(
				"UseManufacturingExecutionSystem",
				ValueOfOptionsAfterChange.UseOperationManagement
					And ValueOfOptionsAfterChange.UseManufacturingExecutionSystem);
			
		EndIf;
		
		If ValueOfOptionsAfterChange.UseShiftTasks <>
				ValueOfOptionsBeforeChange.UseShiftTasks Then
			
			ServiceConstants_.Insert(
				"UseShiftTasks",
				ValueOfOptionsAfterChange.UseShiftTasks);
			
		EndIf;
		
	Else
		
		
		If ValueOfOptionsAfterChange.UseOperationManagement Then
			
			If ValueOfOptionsAfterChange.UseManufacturingExecutionSystem Then
				
				ServiceConstants_.Insert("UseManufacturingExecutionSystem", True);
				
			Else
				
				ServiceConstants_.Insert("UseOperationManagement", True);
				
			EndIf;
			
		EndIf;
		
		If ValueOfOptionsAfterChange.UseShiftTasks Then
			
			ServiceConstants_.Insert("UseShiftTasks", True);
			
		EndIf;
		
	EndIf;
	
	If ValueIsFilled(ServiceConstants_) Then
		Catalogs.BusinessStructure.FillInManagementTechniquesUsed(ServiceConstants_);
	EndIf;
	
	Catalogs.ProductionSites.ConfigureUseOfProperties();
	If AdditionalProperties.CalculateProductionDuration Then
		
		InformationRegisters.JobsOfStandardProductionDurationCalculation.AddJob(Ref, True, True);
		
	EndIf;
	TMCommonUse.SyncKeys(ThisObject);	
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then 
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	ModifiedObjects = CommonClientServer.ValueInArray(Ref);
	Catalogs.ItemKinds.DeleteObjectsFromSeriesAccountingPolicies(ModifiedObjects);
	SetPrivilegedMode(False);
	
EndProcedure
Procedure OnReadPresentationsAtServer() Export
	
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	
EndProcedure

#EndRegion

#Region Private

Function KeySynchronizationSettings()
	
	Result = New Map;
	
	Result.Insert("Catalog.InventoryKinds", "DeletionMark");
	Result.Insert("Catalog.InventoryLocationAttributeKeys", "DeletionMark");
	Result.Insert("Catalog.DocumentRegistryKeys", "DeletionMark,Description");
	
	Return Result;
	
EndFunction

Procedure UpdateUsageFlag()
	
	If Not GetFunctionalOption("UseItemsBatch") Then
		Return;
	EndIf;
	
	If AdditionalProperties.Property("SkipUpdatingSeriesUsageFlag") Then
		Return;
	EndIf;
	
	If Not ProductionBusinessUnit Then
		UseItemsBatch  = False;
		UseCostAccountingByBatches = False;
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MAX(
	|		CASE WHEN NOT BatchAccountingPolicies.BatchAccountingPolicy IS NULL
	|			AND BatchAccountingPolicies.BatchAccountingPolicy <> VALUE(Catalog.BatchAccountingPolicies.SeriesAreNotUsed)
	|			THEN TRUE
	|		ELSE
	|			FALSE
	|		END
	|	) AS UseItemsBatch,
	|	MAX(
	|		ISNULL(BatchAccountingPolicies.BatchAccountingPolicy.UseCostAccountingByBatches, FALSE)
	|	) AS UseCostAccountingByBatches
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS BatchAccountingPolicies
	|
	|WHERE
	|	BatchAccountingPolicies.Warehouse = &Department";
	Query.SetParameter("Department", AdditionalProperties.Ref);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	UseItemsBatch  = Selection.UseItemsBatch;
	UseCostAccountingByBatches = Selection.UseCostAccountingByBatches;
	
EndProcedure

Procedure AddWHDivisionToAccountForSeriesOfProductTypes(ChangeableDivision)
	
	If GetFunctionalOption("UseItemsBatch") 
		And (IsNew()
		And ProductionBusinessUnit 
		Or AdditionalProperties.ChangedAttribute) Then
		
		SetPrivilegedMode(True);
		
		ModifiedObjects = CommonClientServer.ValueInArray(ChangeableDivision);
		If ProductionBusinessUnit Then
			Catalogs.ItemKinds.AddObjectsToBatchAccountingPolicies(ModifiedObjects);
		Else
			Catalogs.ItemKinds.DeleteObjectsFromSeriesAccountingPolicies(ModifiedObjects);
		EndIf;
		
	EndIf;
	
EndProcedure

Function ItIsNecessaryToCalculateDurationOfProduction(Cancel)
	
	If Cancel Or IsNew() Or Not ProductionBusinessUnit Then
		Return False;
	EndIf;
	If AdditionalProperties.Property("ChangedAttribute")
		And AdditionalProperties.ChangedAttribute Then
		Return True;
	EndIf;
	
	Query = New Query(
		"SELECT
		|	ISNULL(Schedules.WorkScheduleCalendar, MainEnterpriseCalendar.Value) AS WorkScheduleCalendar
		|FROM
		|	Catalog.BusinessStructure AS BusinessStructure
		|		LEFT JOIN Catalog.BusinessStructure.WorkSchedules AS Schedules
		|		ON BusinessStructure.Ref = Schedules.Ref
		|		LEFT JOIN Constant.MainEnterpriseCalendar AS MainEnterpriseCalendar
		|		ON (TRUE)		
		|WHERE
		|	BusinessStructure.Ref = &Ref");
	Query.SetParameter("Ref", Ref);
	ChartsBeforeChanges = Query.Execute().Unload().UnloadColumn("WorkScheduleCalendar");
	
	If WorkSchedules.Count() > 0 Then
		ChartsAfterChange = WorkSchedules.UnloadColumn("WorkScheduleCalendar");
	Else
		ChartsAfterChange = CommonClientServer.ValueInArray(
			Constants.MainEnterpriseCalendar.Get());
	EndIf;
	
	NormBeforeChange = ProductDataManagement.CollapsedAverageHoursByWorkSchedule(ChartsBeforeChanges);
	NormAfterChange = ProductDataManagement.CollapsedAverageHoursByWorkSchedule(ChartsAfterChange);
	
	Return NormBeforeChange <> NormAfterChange;
	
EndFunction
#Region Other


#EndRegion

#EndRegion

#EndIf
#EndIf