#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CommonClientServer.SetDynamicListFilterItem(
				List,
				"NotUsed",
				False,
				DataCompositionComparisonType.Equal,
				NStr("ru = 'Скрывать неиспользуемые';
					|vi = 'Hide unused';
					|en = 'Hide unused'; fa = 'پنهان کردن استفاده‌نشده‌ها';
					|it = 'Hide unused';
					|pl = 'Hide unused';
					|tr = 'Kullanılmayanları gizle'"),
				True,
				DataCompositionSettingsItemViewMode.Normal);
	
EndProcedure

#EndRegion