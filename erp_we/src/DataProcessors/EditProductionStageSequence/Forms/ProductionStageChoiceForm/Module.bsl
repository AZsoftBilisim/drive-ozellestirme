
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("AddressListOfStages") Then 
		Table = GetFromTempStorage(Parameters.AddressListOfStages);
		Object.Stages.Load(Table);
	EndIf;
	
	If Parameters.Property("Filter") Then
		Items.StageList.RowFilter = New FixedStructure(Parameters.Filter);
	EndIf;
	
	Items.ListOfProductionStagesOnTheSide.Format = StrTemplate("BF=; BT='%1'", NStr("vi = 'sản xuất cho bên khác';
																					|ru = 'производство на стороне';
																					|en = 'production by third party'; fa = 'production by third party';
																					|it = 'produzione esterna';
																					|pl = 'produkcja postronna';
																					|tr = 'fason üretim'"));
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlers

&AtClient
Procedure StageListSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessStageSelection();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAStage(Command)
	
	ProcessStageSelection();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ProcessStageSelection()
	
	CurrentData = Items.StageList.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Close(CurrentData.Ref);

EndProcedure

#EndRegion
