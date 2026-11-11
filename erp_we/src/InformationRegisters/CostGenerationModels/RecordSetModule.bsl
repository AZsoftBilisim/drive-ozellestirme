#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	FillInFullNameOfSetting();

EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure FillInFullNameOfSetting()
	
	For Each CurRecord1 In ThisObject Do
		
		ModelName_ =
			NStr("vi = '<Không có cài đặt được chỉ định>';
				|ru = '<Настройки не заданы>';
				|en = '<Settings are not configured>'; fa = '<Settings are not configured>';
				|it = '<Impostazioni non stabilite>';
				|pl = '<Ustawienia nie są określone>';
				|tr = '<Ayarlar yapılmadı>'", Common.DefaultLanguageCode());
		
		ConfigurationIsRequired = False;
		
		If CurRecord1.CostGenerationModel =
			Enums.ModelTypesOfCosting.ReleaseAtCalculatedCost Then
			
			ModelName_ =
				NStr("vi = 'Xuất xưởng thành phẩm';
					|ru = 'Выпуск продукции';
					|en = 'Product release'; fa = 'تولید محصول';
					|it = 'Emissione di prodotti';
					|pl = 'Wyprodukowanie';
					|tr = 'Ürün sürümü'", Common.DefaultLanguageCode());
			
		ElsIf CurRecord1.CostGenerationModel =
			Enums.ModelTypesOfCosting.ProductionIssueAtFixedCost Then
			
			ModelName_ =
				NStr("vi = 'Xuất phế liệu thu hồi';
					|ru = 'Выпуск возвратных отходов';
					|en = 'Recyclable waste release'; fa = 'Recyclable waste release';
					|it = 'Rilascio rifiuti riciclabili';
					|pl = 'Wyprodukowanie zwrotnych odpadów';
					|tr = 'Geri dönüştürülebilir atık çıkışı'", Common.DefaultLanguageCode());
			
		Else
			
			ConfigurationIsRequired = True;
			
		EndIf;
		
		CurRecord1.ConfigurationIsRequired = ConfigurationIsRequired;
		CurRecord1.FullModelName = ModelName_;
		
	EndDo;
		
EndProcedure

#EndRegion

#EndRegion

#EndIf