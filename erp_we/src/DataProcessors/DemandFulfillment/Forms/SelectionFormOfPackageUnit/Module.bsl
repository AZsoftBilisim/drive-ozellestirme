#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	OwnerForSelection = Undefined;
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner") Then
		
		CommonPackages = Undefined;
		
		Owner = Parameters.Filter.Owner;
		If TypeOf(Owner) = Type("CatalogRef.Products") Then
			
			OwnerSPackagingGroupSet = Common.ObjectAttributeValue(Owner, "PackagingGroup");
			
			If OwnerSPackagingGroupSet = Catalogs.PackagingGroups.SpecialForItem Then
				
				OwnerForSelection = Owner;
				CommonPackages = False;
				
			Else
				
				OwnerForSelection = OwnerSPackagingGroupSet;
				If ValueIsFilled(OwnerForSelection) Then
					CommonPackages = True;
				Else
					OwnerForSelection = Undefined;
				EndIf;
				
			EndIf;
			
		ElsIf TypeOf(Owner) = Type("CatalogRef.PackagingGroups") Then
			
			If Owner <> Catalogs.PackagingGroups.SpecialForItem Then
				
				OwnerForSelection = Owner;
				CommonPackages = True;
				
			EndIf;
			
		EndIf;
		
		If OwnerForSelection = Undefined Then
			
			TitleText = NStr("vi = 'Đối với phần tử: ""%Owner%"" chưa xác định việc sử dụng đóng gói';
							|ru = 'Для элемента: ""%Owner%"" использование упаковок не определено';
							|en = 'Packaging units are disabled for the item: %Owner%'; fa = 'Packaging units are disabled for the item: %Owner%';
							|it = 'Per articolo: ""%Owner%"" l''utilizzo di imballaggio non è definito';
							|pl = 'Dla elementu: ""%Owner%"" nie określono użycia opakowań';
							|tr = '""%Owner%"" öğesi için: paketleme ünitesi belirtilmedi'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Owner));
			
			AutoTitle = False;
			Title = TitleText;
			
			Items.List.ReadOnly = True;
			ChoiceProhibition = True;
			
		Else
			
			TitleText = NStr("vi = 'Đóng gói (%Owner%)';
							|ru = 'Упаковки (%Owner%)';
							|en = 'Packaging units (%Owner%)'; fa = 'Packaging units (%Owner%)';
							|it = 'Imballaggi (%Owner%)';
							|pl = 'Opakowania (%Owner%)';
							|tr = 'Paketleme üniteleri (%Owner%)'");
			TitleText = StrReplace(TitleText, "%Owner%", String(OwnerForSelection));
			
			AutoTitle = False;
			Title = TitleText;
			
		EndIf;
		
		If CommonPackages = True Then
			
			Items.WarningDecoration.Visible = True;
			Items.WarningDecoration.Title = Items.WarningDecoration.Title + " """ + String(OwnerForSelection) + """";
			
		Else
			Items.WarningDecoration.Visible = False;
		EndIf;
		
		Parameters.Filter.Owner = OwnerForSelection;
		
		List.Parameters.SetParameterValue("UnitsOfMeasurement", Parameters["UnitsOfMeasurement"]);
		
	EndIf;
	
	List.Parameters.SetParameterValue("Owner", OwnerForSelection);
	
	If ChoiceProhibition Then
		ReadOnly = True;
	EndIf;
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
EndProcedure

#EndRegion

#Region EventHandlersForListItems

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ValueChoice();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ValueChoice();

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure ValueChoice()
	
	If ChoiceProhibition Then
		NotifyChoice(Undefined);
	Else
		CurrentRow = Items.List.CurrentData;
		NotifyChoice(CurrentRow.Ref);
	EndIf;
	
EndProcedure

#EndRegion