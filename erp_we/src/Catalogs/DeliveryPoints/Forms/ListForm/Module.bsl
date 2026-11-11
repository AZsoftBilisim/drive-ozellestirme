//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	SetAvailabilityOfArchivingCommand();

	GoodsDeliveryClientServer.ChangeSelectionOfCurrentPoints(ThisObject);
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ShouldShowUnused(Command)
	
	GoodsDeliveryClientServer.ChangeSelectionOfCurrentPoints(ThisObject);
	
EndProcedure

&AtClient
Procedure ChangeUsageAttribute(Command)
	
	ClearMessages();
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.List); // Array of CatalogRef.DeliveryPoints
	
	For Each CurrentPoint In SelectedRows Do
		
		CurrentData = Items.List.RowData(CurrentPoint);
		
		If Not CurrentData.NotUsed
		   And CurrentData.MainPoint Then
			
			MessageTemplate = NStr("ru = 'Невозможно отключить использование: точка доставки ""%1"" является основным адресом доставки';
									|vi = 'Cannot disable: the ""%1"" delivery point is the main delivery address';
									|en = 'Cannot disable: the ""%1"" delivery point is the main delivery address'; fa = 'Cannot disable: the ""%1"" delivery point is the main delivery address';
									|it = 'Cannot disable: the ""%1"" delivery point is the main delivery address';
									|pl = 'Cannot disable: the ""%1"" delivery point is the main delivery address';
									|tr = 'Kullanım devre dışı bırakılamıyor: ""%1"" teslimat noktası ana teslimat adresidir'");
			PresentationOfPoint = String(CurrentData.Ref);
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate,
				PresentationOfPoint);
				
			CommonClient.MessageToUser(MessageText, CurrentData.Ref);
			
		Else
			
			NewFeature = Not CurrentData.NotUsed;
			ChangeWhetherDeliveryPointIsUsed(CurrentPoint, NewFeature);
			NotifyChanged(CurrentPoint);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	List.ConditionalAppearance.Items.Clear();
	GoodsDelivery.SetUpRegistrationOfUnusedDeliveryPoints(List);
	
EndProcedure

&AtServer
Procedure ChangeWhetherDeliveryPointIsUsed(Val DeliveryPoint, Val NotUsed)
	
	PointObject = DeliveryPoint.GetObject();
	PointObject.NotUsed = NotUsed;
	PointObject.Write();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfArchivingCommand()
	
	If Not AccessRight("Update", Metadata.Catalogs.DeliveryPoints) Then
		
		ItemsNames = New Array; // Array of String
		ItemsNames.Add(Items.FormChangeUsageAttribute.Name);
		ItemsNames.Add(Items.ListContextMenuChangeUsageAttribute.Name);
		
		TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemsNames, "Visible", False);
		
	EndIf;
	
EndProcedure

#EndRegion