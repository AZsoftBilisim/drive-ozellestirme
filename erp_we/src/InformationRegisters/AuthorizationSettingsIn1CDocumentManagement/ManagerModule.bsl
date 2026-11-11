#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	StandardProcessing = False;
	Raise NStr("vi = 'Không thể xem hoặc chỉnh sửa các tùy chỉnh đăng nhập vào 1C:Document Management.';
				|ru = 'Настройки авторизации в 1С:Документообороте не предназначены для просмотра или редактирования.';
				|en = 'Authorization settings in 1C:Document Management are not intended for viewing or editing.'; fa = 'Authorization settings in 1C:Document Management are not intended for viewing or editing.';
				|it = 'Le impostazioni di autorizzazione in 1C:Document Management non sono destinati alla visualizzazione o modifica.';
				|pl = 'Ustawienia uwierzytelniania w 1C:Document Management nie są przeznaczone do przeglądu lub edycji.';
				|tr = '1C:Document Management''teki kimlik doğrulama ayarları, görüntüleme veya düzenleme amaçlı değildir.'");
	
EndProcedure

#EndRegion

#EndIf