
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then

		Owner          = Parameters.Filter.Owner;
		OwnerForSelection = Undefined;
		CommonPackages     = Undefined;

		If Owner = Catalogs.PackagingGroups.BasicUnitsOfMeasure Then
			ExceptionText = NStr("vi = 'Biểu mẫu không được dùng để hiển thị một danh sách các đơn vị đo lường.';
								|ru = 'Форма не предназначена для отображения списка единиц измерения.';
								|en = 'The form is not supposed to contain packaging units.'; fa = 'The form is not supposed to contain packaging units.';
								|it = 'Il modulo non ha lo scopo di visualizzare solo l''elenco di unità di imballaggi.';
								|pl = 'Formularz nie jest przeznaczony do odzwierciedlania listy jednostek miary.';
								|tr = 'Form, ölçü birimlerinin listesini görüntülemek için tasarlanmamıştır.'");
			Raise ExceptionText;
		EndIf;	
		
		If TypeOf(Owner) = Type("CatalogRef.Products") Then

			OwnerOfPackagingGroup = Common.ObjectAttributeValue(Owner, "PackagingGroup");

			If OwnerOfPackagingGroup = Catalogs.PackagingGroups.SpecialForItem Then
				OwnerForSelection = Owner;
				CommonPackages = False;
			Else
				OwnerForSelection = OwnerOfPackagingGroup;
				
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
			Title     = TitleText;

			Items.List.ReadOnly = True;
			
		Else
			
			TitleText = NStr("vi = 'Đóng gói (%Owner%)';
							|ru = 'Упаковки (%Owner%)';
							|en = 'Packaging units (%Owner%)'; fa = 'Packaging units (%Owner%)';
							|it = 'Imballaggi (%Owner%)';
							|pl = 'Opakowania (%Owner%)';
							|tr = 'Paketleme üniteleri (%Owner%)'");
			TitleText = StrReplace(TitleText, "%Owner%", String(OwnerForSelection));

			AutoTitle = False;
			Title     = TitleText;
			
		EndIf;
		
		If CommonPackages = True Then
			Items.WarningDecoration.Visible = True;
			Items.WarningDecoration.Title = Items.WarningDecoration.Title + " """ + String(OwnerForSelection) + """";
		Else
			Items.WarningDecoration.Visible = False;
		EndIf;
			
		Parameters.Filter.Owner = OwnerForSelection;
		
		If ValueIsFilled(OwnerForSelection) Then
			Items.Owner.Visible = False;
		EndIf;

	EndIf;
	
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.Core
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ListOnChange(Item)
	Notify("Entry_PackingProductList", Owner);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

