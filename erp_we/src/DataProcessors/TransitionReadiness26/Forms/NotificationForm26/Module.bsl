
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = NStr("vi = 'Thông báo về xóa chức năng cũ trong phiên bản 11.6';
				|ru = 'Уведомление о удалении устаревшей функциональности в редакции 11.6';
				|en = 'Notification of deleting outdated functionality in version 11.6'; fa = 'Notification of deleting outdated functionality in version 11.6';
				|it = 'Notification of deleting outdated functionality in version 11.6';
				|pl = 'Notification of deleting outdated functionality in version 11.6';
				|tr = '11.6 revizyonundan kullanılmayan işlevselliğin kaldırılmasına ilişkin bildirim'");
	Title = NStr("vi = 'Thông báo về xóa chức năng cũ trong phiên bản 2.6';
				|ru = 'Уведомление о удалении устаревшей функциональности в редакции 2.6';
				|en = 'Notification of deleting outdated functionality in version 2.6'; fa = 'Notification of deleting outdated functionality in version 2.6';
				|it = 'Notification of deleting outdated functionality in version 2.6';
				|pl = 'Notification of deleting outdated functionality in version 2.6';
				|tr = '2.6 revizyonundan kullanılmayan işlevselliğin kaldırılmasına ilişkin bildirim'");
	Text = NStr("vi = 'Trong hệ thống sử dụng chức năng cũ mà sẽ bị xóa trong phiên bản 11.6.
	|Nên thực hiện chuyển sang chức năng mới.
	|Có thể tham khảo danh sách thông qua biểu mẫu ""Sẵn sàng chuyển sang phiên bản 11.6"".
	|';
	|ru = 'В системе используется устаревшая функциональность, которая будет удалена в редакции 11.6.
	|Рекомендуется выполнить переход на новую функциональность.
	|Ознакомиться со списком можно через форму ""Готовность перехода на редакцию 11.6"".
	|';
	|en = 'The system uses outdated functionality that will be removed in version 11.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 11.6"" form.
	|'; fa = 'The system uses outdated functionality that will be removed in version 11.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 11.6"" form.
	|';
	|it = 'The system uses outdated functionality that will be removed in version 11.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 11.6"" form.
	|';
	|pl = 'The system uses outdated functionality that will be removed in version 11.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 11.6"" form.
	|';
	|tr = 'Sistemde, 11.6 revizyonundan kaldırılacak kullanım dışı bir işlevsellik kullanılıyor.
	|Yeni işlevselliğe geçiş yapılması önerilir.
	|Listeyi ""11.6 revizyonuna geçişe hazırlık"" formu üzerinden inceleyebilirsiniz.
	|'");
	Ref = New FormattedString(NStr("vi = 'Sẵn sàng chuyển sang phiên bản 11.6';
									|ru = 'Готовность перехода на редакцию 11.6.';
									|en = 'Readiness to migrate to version 11.6.'; fa = 'Readiness to migrate to version 11.6.';
									|it = 'Readiness to migrate to version 11.6.';
									|pl = 'Readiness to migrate to version 11.6.';
									|tr = '11.6 sürümüne geçişe hazır olma durumu.'"),,,, "OpenReadyToGoForm26");
	Text = NStr("vi = 'Trong hệ thống sử dụng chức năng cũ mà sẽ bị xóa trong phiên bản 2.6.
	|Nên thực hiện chuyển sang chức năng mới.
	|Có thể tham khảo danh sách thông qua biểu mẫu ""Sẵn sàng chuyển sang phiên bản 2.6"".
	|';
	|ru = 'В системе используется устаревшая функциональность, которая будет удалена в редакции 2.6.
	|Рекомендуется выполнить переход на новую функциональность.
	|Ознакомиться со списком можно через форму ""Готовность перехода на редакцию 2.6"".
	|';
	|en = 'The system uses outdated functionality that will be removed in version 2.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 2.6"" form.
	|'; fa = 'The system uses outdated functionality that will be removed in version 2.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 2.6"" form.
	|';
	|it = 'The system uses outdated functionality that will be removed in version 2.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 2.6"" form.
	|';
	|pl = 'The system uses outdated functionality that will be removed in version 2.6.
	|It is recommended that you migrate to the new functionality.
	|You can view the list via the ""Readiness to migrate to version 2.6"" form.
	|';
	|tr = 'Sistemde, 2.6 revizyonundan kaldırılacak kullanım dışı bir işlevsellik kullanılıyor.
	|Yeni işlevselliğe geçiş yapılması önerilir.
	|Listeyi ""2.6 revizyonuna geçişe hazırlık"" formu üzerinden inceleyebilirsiniz.
	|'");
	Ref = New FormattedString(NStr("vi = 'Sẵn sàng chuyển sang phiên bản 2.6';
									|ru = 'Готовность перехода на редакцию 2.6.';
									|en = 'Readiness to migrate to version 2.6.'; fa = 'Readiness to migrate to version 2.6.';
									|it = 'Readiness to migrate to version 2.6.';
									|pl = 'Readiness to migrate to version 2.6.';
									|tr = '2.6 sürümüne geçişe hazır olma durumu.'"),,,, "OpenReadyToGoForm26");
	InformationBar = New FormattedString(Text, Ref);
	DataProcessors.TransitionReadiness26.SetNotificationConstantForOutdatedFunctionality(False);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure InformationBarURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "OpenReadyToGoForm26" Then
		StandardProcessing = False;
		OpenForm("DataProcessor.TransitionReadiness26.Form.Form");
		Close();
	EndIf;
EndProcedure

#EndRegion
