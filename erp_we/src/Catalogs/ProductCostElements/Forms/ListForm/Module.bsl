
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	BlockedArticles = New ValueList;
	BlockedArticles.Add(Catalogs.ProductCostElements.TransportationAndProcurementExpenses);
	BlockedArticles.Add(Catalogs.ProductCostElements.CostCalculationError);
	If GetFunctionalOption("ComplexAutomation") Then
		BlockedArticles.Add(Catalogs.ProductCostElements.ProductsBeingDisassembled);
		BlockedArticles.Add(Catalogs.ProductCostElements.ProductsUnderRepair);
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(
		List, "Ref", BlockedArticles, 
		DataCompositionComparisonType.NotInList,
		NStr("vi = 'Ẩn các bài viết tính giá dịch vụ';
			|ru = 'Скрывать служебные статьи калькуляции';
			|en = 'Hide internal product cost elements'; fa = 'Hide internal product cost elements';
			|it = 'Hide internal product cost elements';
			|pl = 'Hide internal product cost elements';
			|tr = 'Hizmet ürün maliyet kalemlerini gizle'"),
		True,
		DataCompositionSettingsItemViewMode.Normal);

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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion