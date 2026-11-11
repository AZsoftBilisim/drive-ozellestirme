
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ListOfObjectsOfOperation = New ValueList;
	
	FillInListOfObjectsAvailableForSelection(ListOfObjectsOfOperation);
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		ListOfObjectsOfOperation,
		DataCompositionComparisonType.InList,
		,
		True,
		DataCompositionSettingsItemViewMode.Inaccessible);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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

#Region FormCommandsEventHandlers

#Region StandardSubsystems

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Items.List);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfObjectsAvailableForSelection(ListOfObjectsOfOperation)
	
	UseRMManagement = GetFunctionalOption("UseRMManagement");
	If UseRMManagement Then

		QueryText =
		"SELECT DISTINCT
		|	ClassMetricParameters.Ref
		|INTO Classes
		|FROM
		|	Catalog.MaintenanceSchemes.RunningTimeValues AS ClassMetricParameters
		|WHERE
		|	NOT ClassMetricParameters.Ref.DeletionMark
		|	AND CASE
		|			WHEN &RunningTimeRegistration
		|				THEN NOT ClassMetricParameters.RegisterBySource
		|			WHEN &SettingTheOperatingTime
		|				THEN TRUE
		|			WHEN &SourceOfTheOperatingTimeIndicator
		|				THEN ClassMetricParameters.RunningTimeValue = &RunningTimeValue
		|			ELSE TRUE
		|		END
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Assets.Ref AS Ref
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	Assets.Ref <> &ConsumerOfOperatingTime
		|	AND Assets.Class IN
		|			(SELECT
		|				Classes.Ref
		|			FROM
		|				Classes AS Classes)
		|
		|UNION ALL
		|
		|SELECT
		|	Assets.Ref
		|FROM
		|	Catalog.Assets AS Assets
		|WHERE
		|	NOT &SourceOfTheOperatingTimeIndicator
		|	AND Assets.Ref <> &ConsumerOfOperatingTime
		|	AND Assets.Ref IN
		|			(SELECT
		|				Nodes.Owner
		|			FROM
		|				Catalog.SubAssets AS Nodes
		|			WHERE
		|				Nodes.Class IN
		|					(SELECT
		|						Classes.Ref
		|					FROM
		|						Classes AS Classes))";
		
	Else
		QueryText = AssetsLocalization.RequestTextForObjectsAvailableForSelection();
		
		If QueryText = Undefined Then
			
			QueryText =
			"SELECT ALLOWED
			|	SliceFAInformation.FixedAsset AS Ref
			|FROM
			|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(, &RunningTimeRegistration AND CorrectionDate = DATETIME(1,1,1)) AS SliceFAInformation
			|WHERE
			|	SliceFAInformation.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)";
			
		EndIf; 
	EndIf;
	Query = New Query(QueryText);
	
	Query.SetParameter(
		"RunningTimeRegistration",
		Parameters.Property("RunningTimeRegistration") And Parameters.RunningTimeRegistration);
		
	Query.SetParameter(
		"SettingTheOperatingTime",
		Parameters.Property("SettingTheOperatingTime") And Parameters.SettingTheOperatingTime);
		
	Query.SetParameter(
		"SourceOfTheOperatingTimeIndicator",
		Parameters.Property("SourceOfTheOperatingTimeIndicator") And Parameters.SourceOfTheOperatingTimeIndicator);
		
	Query.SetParameter(
		"RunningTimeValue",
		?(Parameters.Property("RunningTimeValue"), Parameters.RunningTimeValue, Undefined));
		
	Query.SetParameter(
		"ConsumerOfOperatingTime",
		?(Parameters.Property("ConsumerOfOperatingTime"), Parameters.ConsumerOfOperatingTime, Undefined));
	
	ListOfObjectsOfOperation.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

#EndRegion
