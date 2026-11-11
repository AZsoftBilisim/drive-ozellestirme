// @strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("VehicleType_")
		And ValueIsFilled(Parameters.Filter.VehicleType_) Then
		
		LoadSettings();
		
		VehicleType_ = Parameters.Filter.VehicleType_;
		
		TitleTemplate1 = NStr("vi = 'Theo kiểu ""%1""';
								|ru = 'По типу ""%1""';
								|en = 'By the ""%1"" type'; fa = 'By the ""%1"" type';
								|it = 'По типу ""%1""';
								|pl = 'By the ""%1"" type';
								|tr = '""%1"" türünde'");
		TitleText = StringFunctionsClientServer.SubstituteParametersToString(
			TitleTemplate1,
			String(VehicleType_));
		Items.ByVehicleType.Title = TitleText;
		
		If GetNumberOfVehiclesByType(VehicleType_) = 0 Then
			ByVehicleType = False;
		EndIf;
		
		Parameters.Filter.Delete("VehicleType_");
		If ByVehicleType Then
			SetSelectedVehicleTypeServer();
		EndIf;
	Else
		VehicleType_ = Catalogs.VehicleTypes.EmptyRef();
		Items.ByVehicleType.Visible = False;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ByVehicleTypeOnChange(Item)
	
	If ByVehicleType Then
		SetSelectedVehicleType();
	Else
		TMCommonUseClientServer.GetDynamicListSelection(List).Items.Clear();
	EndIf;
	
	ShouldSaveSettings();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// Parameters:
//   Command - FormCommand - executed command
//
&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  VehicleType_ - CatalogRef.VehicleTypes - Type of vehicle
// 
// Returns:
//  Number
//
&AtServer
Function GetNumberOfVehiclesByType(VehicleType_)
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	ISNULL(VlTab.Count, 0) AS Count
	|FROM
	|	(SELECT
	|		SUM(1) AS Count
	|	FROM
	|		Catalog.Vehicles AS Vehicles
	|	WHERE
	|		Vehicles.Type = &Type) AS VlTab";
	
	Query.SetParameter("Type", VehicleType_);
	
	Return Query.Execute().Unload()[0].Count;
	
EndFunction

&AtServer
Procedure LoadSettings()
	
	SettingsValue = Common.CommonSettingsStorageLoad("Catalogs.Vehicles", "");
	If TypeOf(SettingsValue) = Type("Map") Then
		ByVehicleType = SettingsValue.Get("ByVehicleType");
	Else
		ByVehicleType = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	Var Settings; // Map
	
	Settings = New Map;
	Settings.Insert("ByVehicleType", ByVehicleType);
	
	Common.CommonSettingsStorageSave("Catalogs.Vehicles", "",Settings);

EndProcedure

&AtClient
Procedure SetSelectedVehicleType()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Type",
		VehicleType_,
		DataCompositionComparisonType.Equal,
		,
		True);
	
EndProcedure

&AtServer
Procedure SetSelectedVehicleTypeServer()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Type",
		VehicleType_,
		DataCompositionComparisonType.Equal,
		,
		True);
	
EndProcedure

#EndRegion