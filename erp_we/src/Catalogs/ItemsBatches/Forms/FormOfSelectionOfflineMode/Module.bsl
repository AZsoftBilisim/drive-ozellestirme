
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	ParametersCurLine = Undefined;
	If ValueIsFilled(Parameters.ProductKind) Then
		ProductKind = Parameters.ProductKind;
	ElsIf Parameters.Property("CurrentRow", ParametersCurLine) And ValueIsFilled(ParametersCurLine) Then
		SeriesAttributes = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(ParametersCurLine,
			New Structure("ProductKind", "ProductKind"));
		
		ProductKind = SeriesAttributes.ProductKind;
	ElsIf ValueIsFilled(Parameters.Products) Then
		ProductAttributes = MobileWarehouseKeeperWorkspace.ObjectAttributesValues(Parameters.Products,
			New Structure("ProductKind", "ProductKind"));
		
		ProductKind = ProductAttributes.ProductKind;
	EndIf;
	
	If Parameters.Property("ExpirationDate_") Then
		ExpirationDate_ = Parameters.ExpirationDate_;
	EndIf;
	
	Items.ProductKind.ReadOnly = ValueIsFilled(ProductKind);
	
	ProductKindOnChangeServer();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And MobileWarehouseKeeperWorkspaceClient.ThereIsRawEvent() Then
			
			Number = MobileWarehouseKeeperWorkspaceClient.ConvertDataFromScannerToStructure(Parameter).Barcode;
			
			MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(List,
																					"Number",
																					Number,
																					DataCompositionComparisonType.Contains,
																					,
																					ValueIsFilled(Number));
			
		EndIf;
	EndIf;
	// End Peripherals
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ProductKindOnChange(Item)
	
	ProductKindOnChangeServer();
	
EndProcedure

#EndRegion

#Region Private

#Region Other

&AtServer
Procedure ProductKindOnChangeServer()
	
	TemplateParameters = Undefined;
	BatchOwner = Catalogs.ItemKinds.EmptyRef();
	
	If ValueIsFilled(ProductKind) Then
		
		TemplateParameters = New FixedStructure(
			MobileWarehouseKeeperWorkspace.SeriesUseSettings(ProductKind));
		
		BatchOwner = TemplateParameters.BatchOwner;
		
		For Each LongDesc In TemplateParameters.DescriptionsOfUseOfSeriesProps Do
			
			If ValueIsFilled(LongDesc.Format)
				And Items.Find(LongDesc.AttributeName) <> Undefined Then
				Items[LongDesc.AttributeName].Format = LongDesc.Format;
			EndIf;
			
		EndDo;
		
	EndIf;
	
	MobileWarehouseKeeperWorkspaceClientServer.SetDynamicListFilterItem(List,
		"ProductKind",
		BatchOwner,
		DataCompositionComparisonType.Equal,,
		True);
	
	CustomizeByTemplate();
	
EndProcedure

&AtServer
Procedure CustomizeByTemplate()
	
	If TemplateParameters = Undefined Or (ValueIsFilled(TemplateParameters)
		And Not TemplateParameters.KeepAccountingByBatch) Then
		
		DescriptionsOfUseOfSeriesProps = MobileWarehouseKeeperWorkspace.DescriptionsOfUseOfSeriesProps();
		
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

#EndRegion
