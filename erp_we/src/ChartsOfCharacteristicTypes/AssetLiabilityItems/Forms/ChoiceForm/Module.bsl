
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	SetDynamicListParameters();
	
	Title = NStr("vi = 'Dạng tài sản và nguồn vốn';
				|ru = 'Статьи активов и пассивов';
				|en = 'Asset and liability items'; fa = 'اقلام دارایی و بدهی';
				|it = 'Статьи активов и пассивов';
				|pl = 'Pozycje aktywów i pasywów';
				|tr = 'Varlıklar ve yükümlülükler kalemleri'");
	If Parameters.Property("Filter") And Parameters.Filter.Property("AssetLiability")
		And ValueIsFilled(Parameters.Filter.AssetLiability) Then
		
		ArticleActivity = Parameters.Filter.AssetLiability;
		
		AssetBalanceSheetName = Enums.KindsOfBalanceSheetStatementItems.AssetBalanceSheetName;
		Liabilities = Enums.KindsOfBalanceSheetStatementItems.Liabilities;
		AssetItems = NStr("vi = 'Dạng tài sản';
							|ru = 'Статьи активов';
							|en = 'Asset items'; fa = 'Asset items';
							|it = 'Статьи активов';
							|pl = 'Pozycje aktywów';
							|tr = 'Varlık kalemleri'");
		LiabilityItems = NStr("vi = 'Dạng nguồn vốn';
								|ru = 'Статьи пассивов';
								|en = 'Liability items'; fa = 'Liability items';
								|it = 'Статьи пассивов';
								|pl = 'Pozycje pasywów';
								|tr = 'Yükümlülük kalemleri'");
		
		If ArticleActivity = AssetBalanceSheetName Then
			Title = AssetItems;
			
		ElsIf ArticleActivity = Liabilities Then
			Title = LiabilityItems;
			
		ElsIf TypeOf(ArticleActivity) = Type("Array") Then
			If ArticleActivity.Find(AssetBalanceSheetName) <> Undefined Then
				Title = AssetItems;
			ElsIf ArticleActivity.Find(Liabilities) <> Undefined Then
				Title = LiabilityItems;
			EndIf;
			
		EndIf;
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	TypesList = List.SettingsComposer.Settings.Selection.SelectionAvailableFields.FindField(New DataCompositionField("Ref")).Type;
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = TypesList;
	PlacementParameters.CommandBar = Items.FormCommandBar;
	
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core	
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

#EndRegion

#Region Private

&AtServer
Procedure SetDynamicListParameters()
	
	CommonClientServer.SetDynamicListFilterItem(
		List,
		"Ref",
		ChartsOfCharacteristicTypes.AssetLiabilityItems.BlockedItemsOfAssetsLiabilities(),
		DataCompositionComparisonType.NotInList);
	
	CommonClientServer.SetDynamicListParameter(
		List,
		"OtherAssetsAndLiabilitiesRecords",
		 Metadata.AccumulationRegisters.OtherAssetsAndLiabilitiesRecords.Name);
	
EndProcedure

#EndRegion


