#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Items.DetailsDecoration.Visible = ValueIsFilled(Parameters.DetailsDecoration);
	Items.DetailsDecoration.Title = Parameters.DetailsDecoration;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ExternalResourceOpening(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	If ValueIsFilled(Item.EditText) Then
		FileSystemClient.OpenURL(Item.EditText);
	Else
		ShowMessageBox(, NStr("vi = 'Nhập địa chỉ liên kết ngoài.';
								|ru = 'Введите адрес внешней ссылки.';
								|en = 'Enter the external link address.'; fa = 'Enter the external link address.';
								|it = 'Enter the external link address.';
								|pl = 'Enter the external link address.';
								|tr = 'Harici bağlantı adresi girin.'"));
	EndIf;
	
EndProcedure

&AtClient
Procedure ExternalResourceOnChange(Item)
	
	If StrStartsWith(ExternalResource, "e1cib") Then
		WarningText = 
			NStr("vi = 'Đối với đối tượng trong cơ sở thông tin khác, cần sử dụng liên kết ngoài.';
				|ru = 'Для объектов в других информационных базах следует использовать внешние ссылки.';
				|en = 'Use external links for objects in other infobases.'; fa = 'Use external links for objects in other infobases.';
				|it = 'Use external links for objects in other infobases.';
				|pl = 'Use external links for objects in other infobases.';
				|tr = 'Diğer infobase''lerdeki nesneler için harici bağlantılar kullanılmalıdır.'");
	Else
		WarningText = "";
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	If Not ValueIsFilled(ExternalResource) Then
		ShowMessageBox(, NStr("vi = 'Nhập địa chỉ liên kết ngoài.';
								|ru = 'Введите адрес внешней ссылки.';
								|en = 'Enter the external link address.'; fa = 'Enter the external link address.';
								|it = 'Enter the external link address.';
								|pl = 'Enter the external link address.';
								|tr = 'Harici bağlantı adresi girin.'"));
		Return;
	EndIf;
	
	If StrLen(ExternalResource) > 250 Then
		ShowMessageBox(, NStr("vi = 'Độ dài liên kết ngoài không thể vượt quá 250 ký tự.
			|Hãy sử dụng công cụ rút gọn liên kết.';
			|ru = 'Длина внешней ссылки не может превышать 250 символов.
			|Используйте сервисы сокращения ссылок.';
			|en = 'The length of the external link cannot exceed 250 characters.
			|Use link shortening services.'; fa = 'The length of the external link cannot exceed 250 characters.
			|Use link shortening services.';
			|it = 'The length of the external link cannot exceed 250 characters.
			|Use link shortening services.';
			|pl = 'The length of the external link cannot exceed 250 characters.
			|Use link shortening services.';
			|tr = 'Harici bağlantıların uzunluğu 250 karakteri geçemez.
			|Bağlantı kısaltma hizmetlerini kullanın.'"));
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("ExternalResource", ExternalResource);
	Result.Insert("Comment", Comment);
	
	Close(Result);

EndProcedure

#EndRegion