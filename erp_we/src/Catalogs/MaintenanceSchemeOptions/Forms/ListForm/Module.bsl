
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Owner") Then
		
		Owner = Parameters.Filter.Owner;
		
		UseOfSubclasses = Common.ObjectAttributeValue(Owner, "UseOfSubclasses");
		
		If Not ValueIsFilled(UseOfSubclasses) Or Not UseOfSubclasses Then
			
			TitleText = NStr("vi = 'Đối với mục: ""%Owner%"" không có phân loại lớp dưới ';
							|ru = 'Для элемента: ""%Owner%"" использование подклассов не определено';
							|en = 'Usage of maintenance scheme options is not determined for item: ""%Owner%""'; fa = 'Usage of maintenance scheme options is not determined for item: ""%Owner%""';
							|it = 'Per elemento: ""%Owner%"" l''utilizzo delle sottoclassi non è definito';
							|pl = 'Dla elementu: ""%Owner%"" nie określono użycia podklas';
							|tr = '""%Owner%"" öğesi için: alt sınıf ünitesi belirtilmedi'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Owner));
			
			AutoTitle = False;
			Title = TitleText;
			
			Items.List.ReadOnly = True;
			
		Else
			
			TitleText = NStr("vi = 'Phân loại lớp dưới của các đối tượng sửa chữa (%Owner%)';
							|ru = 'Подклассы объектов ремонта (%Owner%)';
							|en = 'R&M object subclasses (%Owner%)'; fa = 'R&M object subclasses (%Owner%)';
							|it = 'Sottoclassi di oggetti di manutenzione (%Owner%)';
							|pl = 'Podklasy obiektów remontu (%Owner%)';
							|tr = 'Onarım nesneleri alt sınıfları (%Owner%)'");
			TitleText = StrReplace(TitleText, "%Owner%", String(Owner));
			
			AutoTitle = False;
			Title = TitleText;
			
		EndIf;
		
	EndIf;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion
#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

