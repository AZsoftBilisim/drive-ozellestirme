#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	SelectionCell = Parameters.SelectionCell;
	Warehouse  = Parameters.Warehouse;
	
	If Parameters.Property("Goods") Then
		
		If Parameters.Goods.Count() > 0 Then
			SelectionCell = Parameters.Goods[0].SelectionCell;
			CellPlacement = Parameters.Goods[0].CellPlacement;
		EndIf;
		
		For Each String In Parameters.Goods Do
			
			NewRow = Goods.Add();
			FillPropertyValues(NewRow, String);
			
		EndDo;
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GoodsProfile.Visible Then
		
		Cancel = True;
		StandardProcessing = False;
		
		Items.ForPlacement.Visible = True;
		Items.GoodsProfile.Visible = False;
		Items.Scan.Visible = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoodsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Items.ForPlacement.Visible = False;
	Items.GoodsProfile.Visible = True;
	Items.Scan.Visible = False;
	
	Products       = Item.CurrentData.Products;
	Characteristic     = Item.CurrentData.Characteristic;
	Series              = Item.CurrentData.Series;
	Purpose         = Item.CurrentData.Purpose;
	Package           = Item.CurrentData.Package;
	NumberOfPackages = Item.CurrentData.NumberOfPackages;
	SKU            = Item.CurrentData.SKU;
	
	If SelectionCell <> Item.CurrentData.Cell Then
		
		CellPlacement = Item.CurrentData.ReplacementCell;
		Items.Cell.Visible = False;
		Items.ReplacementCell.Visible = True;
		
	EndIf;
	
	Items.Series.Visible = ValueIsFilled(Series);
	Items.Characteristic.Visible = ValueIsFilled(Characteristic);
	
EndProcedure

&AtClient
Procedure Confirm(Command)
	
	Items.ForPlacement.Visible = True;
	Items.GoodsProfile.Visible = False;
	Items.Scan.Visible = True;
	Items.Cell.Visible = True;
	Items.ReplacementCell.Visible = False;
	
	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", Products);
	TheStructureOfTheSearch.Insert("Characteristic", Characteristic);
	TheStructureOfTheSearch.Insert("Series", Series);
	TheStructureOfTheSearch.Insert("Package", Package);
	
	ArrayOfFound = Goods.FindRows(TheStructureOfTheSearch);
	For Each String In ArrayOfFound Do
		String.NumberOfPackagesPlaced = NumberOfPackages;
		If ValueIsFilled(CellPlacement) Then
			String.ReplacementCell = CellPlacement;
		EndIf;
	EndDo;
	
	CellPlacement = Undefined;
	
EndProcedure

&AtClient
Procedure MoveTo(Command)
	
	ArrayOfPlacements = New Array;
	
	For Each String In Goods Do
		
		Structure = StructureOfGoods();
		
		FillPropertyValues(Structure, String);
		Structure.Insert("NumberOfPackages", String.NumberOfPackagesPlaced);
		
		ArrayOfPlacements.Add(Structure);
		
	EndDo;
	
	BuildResult = New Structure;
	BuildResult.Insert("Cell", SelectionCell);
	BuildResult.Insert("ArrayOfPlacements", ArrayOfPlacements);
	
	Close(BuildResult);
	
EndProcedure

&AtClient
Procedure ReducedAmount(Command)
	
	NumberOfPackages = NumberOfPackages - 1;
	
	If NumberOfPackages < 0 Then
		NumberOfPackages = 0 ;
	EndIf;
	
EndProcedure

&AtClient
Procedure IncreasedAmount(Command)
	NumberOfPackages = NumberOfPackages + 1;
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Items.Count.Font = New Font(, 16, True, , , );
	
EndProcedure

&AtServer
Function StructureOfGoods()
	
	Structure = New Structure;
	Structure.Insert("Products","");
	Structure.Insert("Characteristic","");
	Structure.Insert("Series","");
	Structure.Insert("Package","");
	Structure.Insert("NumberOfPackages","");
	Structure.Insert("Cell","");
	Structure.Insert("ReplacementCell","");
	
	Return Structure;
	
EndFunction

&AtClient
Procedure ResultOfCellReplacement(Result = Undefined, AdditionalParameters = Undefined) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CellPlacement = Result;
	Items.Cell.Visible = False;
	Items.ReplacementCell.Visible = True;
	
EndProcedure

#EndRegion