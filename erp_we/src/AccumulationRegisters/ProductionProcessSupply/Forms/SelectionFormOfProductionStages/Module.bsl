
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	ConfigureSelectionByRecipient();
	
	SetUpDynamicList();
	
	SetFormHeader();
	
	ConfigurationModificationOverridable.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure FilterByRecipientOnChange(Item)
	
	CommonClientServer.SetDynamicListParameter(List, "FilterByRecipient", FilterByRecipient);
	
EndProcedure

#EndRegion

#Region EventHandlersForListItems

&AtClient
Procedure ListValueChoice(Item, Value, StandardProcessing)
	
	If Items.List.CurrentData <> Undefined Then
		SelectionValue = Items.List.CurrentData.StageConsumer;
	Else
		SelectionValue = Undefined;
	EndIf;
	
	NotifyChoice(SelectionValue);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	Return; // no actions are provided in this configuration
	
EndProcedure

&AtServer
Procedure ConfigureSelectionByRecipient()
	
	FilterByRecipient = Parameters.Property("Recipient") And ValueIsFilled(Parameters.Recipient);
	If FilterByRecipient Then
		If TypeOf(Parameters.Recipient) = Type("CatalogRef.Warehouses") Then
			Template = NStr("vi = 'Nhu cầu tại kho: ""%1""';
							|ru = 'Потребность на складе: ""%1""';
							|en = 'Demand in warehouse: ""%1""'; fa = 'Demand in warehouse: ""%1""';
							|it = 'Fabbisogno di magazzino: ""%1""';
							|pl = 'Zapotrzebowanie w magazynie: ""%1""';
							|tr = 'Ambardaki gereksinim: ""%1""'");
		Else
			Template = NStr("vi = 'Nhu cầu tại bộ phận: ""%1""';
							|ru = 'Потребность в подразделении: ""%1""';
							|en = 'Demand in business unit: ""%1""'; fa = 'Demand in business unit: ""%1""';
							|it = 'Fabbisogno di reparto: ""%1""';
							|pl = 'Zapotrzebowanie w dziale: ""%1""';
							|tr = 'Departman talebi: ""%1""'");
		EndIf;
		Items.FilterByRecipient.Title = StrTemplate(Template, Parameters.Recipient);
	EndIf;
	Items.FilterByRecipient.Visible = FilterByRecipient;

EndProcedure

&AtServer
Procedure SetUpDynamicList()
	
	CommonClientServer.SetDynamicListParameter(List, "ReferenceOrder", Parameters.ReferenceOrder);
	
	CommonClientServer.SetDynamicListParameter(List, "Products", Parameters.Products);
	CommonClientServer.SetDynamicListParameter(List, "Characteristic", Parameters.Characteristic);
	CommonClientServer.SetDynamicListParameter(List, "Purpose", Parameters.Purpose);
	
	If TypeOf(Parameters.Recipient) = Type("CatalogRef.Warehouses") Then
		CommonClientServer.SetDynamicListParameter(List, "Warehouse", Parameters.Recipient);
	Else
		CommonClientServer.SetDynamicListParameter(List, "Warehouse", Catalogs.Warehouses.EmptyRef());
	EndIf;
	If TypeOf(Parameters.Recipient) = Type("CatalogRef.BusinessStructure") Then
		CommonClientServer.SetDynamicListParameter(List, "Department", Parameters.Recipient);
	Else
		CommonClientServer.SetDynamicListParameter(List, "Department", Catalogs.BusinessStructure.EmptyRef());
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "FilterByRecipient", FilterByRecipient);
	
	CommonClientServer.SetDynamicListParameter(List, "Predecessors", Documents.ProductionStage2_2.AllPredecessors(Parameters.Source));
	CommonClientServer.SetDynamicListParameter(List, "Recorder", Parameters.Source);
	
	CommonClientServer.SetDynamicListParameter(List, "EmptyStageLink", Documents.ProductionStage2_2.EmptyRef());
	
EndProcedure

&AtServer
Procedure SetFormHeader()
	
	TextProducts = StrTemplate(NStr("vi = 'Mặt hàng: %1';
									|ru = 'Номенклатура: %1';
									|en = 'Items: %1'; fa = 'Items: %1';
									|it = 'Articolo: %1';
									|pl = 'Towary: %1';
									|tr = 'Öğe: %1'"), Parameters.Products);
	
	If ValueIsFilled(Parameters.Characteristic) Then
		
		TextProducts = TextProducts + ", " + StrTemplate(NStr("vi = 'Đặc tính: %1';
																|ru = 'Характеристика: %1';
																|en = 'Variant: %1'; fa = 'Variant: %1';
																|it = 'Caratteristica: %1';
																|pl = 'Charakterystyka: %1';
																|tr = 'Varyant: %1'"), Parameters.Characteristic);
		
	EndIf;
	
	Title = StrTemplate(NStr("vi = 'Lựa chọn công đoạn tiêu thụ bán thành phẩm (%1)';
							|ru = 'Выбор этапа потребителя полуфабриката (%1)';
							|en = 'Select semi-finished product consumer stage (%1)'; fa = 'Select semi-finished product consumer stage (%1)';
							|it = 'Scelta della fase utente semilavorato (%1)';
							|pl = 'Wybór etapu konsumenta półproduktu (%1)';
							|tr = 'Yarı mamul ürünün tüketici aşamasının seçimi (%1)'"), TextProducts);
	
EndProcedure

#EndRegion
