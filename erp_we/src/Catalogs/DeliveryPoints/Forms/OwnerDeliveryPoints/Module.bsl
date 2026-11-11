//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Parameters.Filter.Property("Owner") Then
		
		MessageText = NStr("ru = 'Форма не предназначена для непосредственного открытия';
							|vi = 'Form is not intended for direct opening';
							|en = 'Form is not intended for direct opening'; fa = 'Form is not intended for direct opening';
							|it = 'Form is not intended for direct opening';
							|pl = 'Form is not intended for direct opening';
							|tr = 'Form doğrudan açılmak için tasarlanmamıştır'");
		Common.MessageToUser(MessageText,,,, Cancel);
		
	EndIf;
	
	Owner = Parameters.Filter.Owner; // CatalogRef.Partners, CatalogRef.Warehouses -
	
	If Parameters.ChoiceMode Then
		
		Items.List.ChoiceMode = True;
		
	EndIf;
	
	If TypeOf(Owner) = Type("CatalogRef.Partners") Then
		
		TitleTemplate1 = NStr("ru = 'Точки доставки по партнеру %1';
								|vi = '%1 partner delivery points';
								|en = '%1 partner delivery points'; fa = '%1 partner delivery points';
								|it = '%1 partner delivery points';
								|pl = '%1 partner delivery points';
								|tr = '%1 partnerine göre teslimat noktaları'");
		
	ElsIf TypeOf(Owner) = Type("CatalogRef.Warehouses") Then
		
		TitleTemplate1 = NStr("ru = 'Точки доставки по складу %1';
								|vi = '%1 warehouse delivery points';
								|en = '%1 warehouse delivery points'; fa = '%1 warehouse delivery points';
								|it = '%1 warehouse delivery points';
								|pl = '%1 warehouse delivery points';
								|tr = '%1 ambarına göre teslimat noktaları'");
		
	Else
		
		ExceptionPattern = NStr("ru = 'Тип владельца точек доставки %1 не поддерживается';
								|vi = 'The %1 owner type of delivery points is not supported';
								|en = 'The %1 owner type of delivery points is not supported'; fa = 'The %1 owner type of delivery points is not supported';
								|it = 'The %1 owner type of delivery points is not supported';
								|pl = 'The %1 owner type of delivery points is not supported';
								|tr = '%1 teslimat noktaları sahibi türü desteklenmiyor'");
		
		OwnerType = TypeOf(Owner);
		TypePresentation = String(OwnerType);
		
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionPattern, TypePresentation);
		
		Raise ExceptionText;
		
	EndIf;
	
	RefsToCheck = CommonClientServer.ValueInArray(Owner);
	
	LinkPresentations = Common.RefsPresentations(RefsToCheck);
	OwnerPresentation = LinkPresentations[Owner];
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, OwnerPresentation);
	
	SetConditionalAppearance();
	
	SetVisibilityOfIdFields();
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
	
	// Font of the main delivery point
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MainPoint");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", StyleFonts.BoldFont);
	
	// The color of the delivery point that is not being used
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

&AtServer
Procedure SetVisibilityOfIdFields()
	
	Items.GroupAddressId.Visible = Common.MetadataObjectAvailableByFunctionalOptions(
		Metadata.Catalogs.DeliveryPoints.Attributes.AddressID);
	
EndProcedure

#EndRegion