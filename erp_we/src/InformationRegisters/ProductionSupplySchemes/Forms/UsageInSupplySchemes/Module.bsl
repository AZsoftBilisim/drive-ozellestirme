#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Department", Parameters.Department);
		
	Title = StrTemplate(NStr("vi = 'Sử dụng trong sơ đồ đảm bảo (%1)';
							|ru = 'Использование в схемах обеспечения (%1)';
							|en = 'Usage in supply schemes (%1)'; fa = 'Usage in supply schemes (%1)';
							|it = 'Utilizzare in schemi di approvvigionamento (%1)';
							|pl = 'Stosowanie w schematach zaopatrzenia (%1)';
							|tr = 'Arz şemalarında kullanım (%1)'"), Parameters.Department);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.SupplyScheme);
	EndIf;
	
EndProcedure

&AtClient
Procedure ListBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	CurrentData = Items.List.CurrentData;
	If CurrentData <> Undefined Then
		ShowValue(, CurrentData.SupplyScheme);
	EndIf;
	
EndProcedure

#EndRegion
