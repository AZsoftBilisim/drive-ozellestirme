
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	CanBeEdited = AccessRight("Edit", Metadata.Catalogs.ItemsBatches);
	
	Items.FormChangeSelectedItems.Visible                 = CanBeEdited;
	Items.ListContextMenuChangeSelectedItems.Visible = CanBeEdited;
	
	ProductKindOnChangeServer();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductKindOnChangeServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ChangeSelectedItems(Command)
	
	BatchEditObjectsClient.ChangeSelectedItems(Items.List);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	If Not Copy Then
		Cancel = True;
		
		If Not ValueIsFilled(ProductKind) Then
			WarningText = NStr("vi = 'Trước khi thêm sê-ri cần chỉ ra dạng mặt hàng.';
								|ru = 'Перед добавлением серии необходимо указать вид номенклатуры.';
								|en = 'Specify item kind before adding the batch.'; fa = 'Specify item kind before adding the batch.';
								|it = 'Prima dell''aggiunta della serie, è necessario indicare il tipo di articolo.';
								|pl = 'Przed dodaniem serii należy wskazać rodzaj pozycji.';
								|tr = 'Parti eklemeden önce ürün türünün belirtilmesi gerekir.'");
			
			ShowMessageBox(Undefined, WarningText);
			
			Return;
		ElsIf ValueIsFilled(TemplateParameters)
			And Not TemplateParameters.KeepAccountingByBatch Then
			
			WarningText = NStr("vi = 'Không thể thêm sê-ri mới, bởi vì trong tùy chỉnh dạng mặt hàng đã tắt tính năng sử dụng sê-ri.';
								|ru = 'Невозможно добавить новую серию, так как в настройках вида номенклатуры выключена возможность использования серий.';
								|en = 'Cannot add a new batch as the capability of using batch is disabled in item kind settings.'; fa = 'Cannot add a new batch as the capability of using batch is disabled in item kind settings.';
								|it = 'Non è possibile aggiungere una nuova serie, poiché nelle impostazioni del tipo di articolo è disabilitata l''opzione per l''utilizzo della serie stessa.';
								|pl = 'Niemożliwe jest dodawanie nowej serii, ponieważ w ustawieniach rodzaju produktów jest włączona możliwość używania serii.';
								|tr = 'Ürün türü ayarlarında parti seçeneği devre dışı bırakıldığı için yeni bir parti eklemek mümkün değildir.'");
			
			ShowMessageBox(Undefined, WarningText);
			
			Return;
			
		EndIf;
		
		FillingValues = New Structure("ProductKind", ProductKind);
		
		OpenForm("Catalog.ItemsBatches.ObjectForm",
			New Structure("FillingValues", FillingValues), Items.List);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ProductKindOnChangeServer()
	
	TemplateParameters = Undefined;
	BatchOwner = Catalogs.ItemKinds.EmptyRef();
	
	If ValueIsFilled(ProductKind) Then
		
		TemplateParameters = New FixedStructure(
			Catalogs.ItemKinds.SeriesUseSettings(ProductKind)
		);
		
		BatchOwner = TemplateParameters.BatchOwner;
		
		For Each LongDesc In TemplateParameters.DescriptionsOfUseOfSeriesProps Do
			
			If ValueIsFilled(LongDesc.Format)
				And Items.Find(LongDesc.AttributeName) <> Undefined Then
				Items[LongDesc.AttributeName].Format = LongDesc.Format;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	CommonClientServer.SetDynamicListFilterItem(List,
		"ProductKind",
		BatchOwner,
		DataCompositionComparisonType.Equal,,
		True
	);
	
	CustomizeForm();
	
EndProcedure

&AtServer
Procedure CustomizeForm()
	
	If TemplateParameters = Undefined
		Or (ValueIsFilled(TemplateParameters)
			And Not TemplateParameters.KeepAccountingByBatch) Then
			
			DescriptionsOfUseOfSeriesProps = Catalogs.ItemKinds.DescriptionsOfUseOfSeriesProps();
			
			For Each LongDesc In DescriptionsOfUseOfSeriesProps Do
				
				Item = Items.Find(LongDesc.AttributeName);
				If Item = Undefined Then
					Continue;
				EndIf;
				
				If Not IsBlankString(LongDesc.AccountingFeatures) Then
					Item.Visible = False;
				EndIf;
			EndDo;	
	Else
		
		For Each LongDesc In TemplateParameters.DescriptionsOfUseOfSeriesProps Do
			
			Item = Items.Find(LongDesc.AttributeName);
			
			If Item = Undefined Then
				Continue;
			EndIf;
			
			Item.Visible = LongDesc.Use;
		EndDo;	
				
	EndIf;
	
EndProcedure

#EndRegion