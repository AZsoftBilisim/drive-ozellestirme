#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckIDUniqueness(Cancel);
	
	If RecordByCurrency And Not ValueIsFilled(CurrencyFilling) Then
		ErrorText = NStr("vi = 'Chưa điền trường ""Nguồn tiền tệ""';
						|ru = 'Поле ""Источник валюты"" не заполнено';
						|en = '""Currency source"" is required'; fa = '""Currency source"" is required';
						|it = 'Campo ""Fonte valuta"" non compilato';
						|pl = 'Nie wypełniono pola ""Źródło waluty""';
						|tr = '""Para birimlerinin kaynağı"" alanı doldurulmamış'");
		Common.MessageToUser(ErrorText,, "CurrencyPresentation", "Object", Cancel);
	EndIf;
	
	If RecordByQuantity Then
		CheckedAttributes.Add("UnitOfMeasureFilling");
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Id = "";
	
EndProcedure

Procedure OnReadPresentationsAtServer() Export
	// StandardSubsystems.Core
	NationalLanguageSupportServer.OnReadPresentationsAtServer(ThisObject);
	// End StandardSubsystems.Core
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure CheckIDUniqueness(Cancel)
	
	If ValueIsFilled(Id) Then
		
		IDVariable = True;
		VerificationID = BudgetReportingClientServer.GetID(Id);
		If Not VerificationID = Id Then
			MessageText = NStr("vi = 'Tên định dạng không tương ứng với quy tắc đặt tên biến.
										|Tên định dạng không được chứa dấu cách và ký tự đặc biệt và không được bắt đầu bằng số.';
										|ru = 'Идентификатор не соответствует правилам именования переменных.
										|Идентификатор не должен содержать пробелов и специальных символов и не должен начинаться с цифры.';
										|en = 'The ID does not comply with the variable naming rules. 
										|The ID must not contain spaces and specific characters and must not start with a number.'; fa = 'The ID does not comply with the variable naming rules. 
										|The ID must not contain spaces and specific characters and must not start with a number.';
										|it = 'L''identificatore non corrisponde alle regole di denominazione delle variabili.
										|L''identificatore non deve contenere spazi e caratteri speciali e non deve iniziare dalla cifra.';
										|pl = 'Identyfikator nie jest zgodne z zasadami nazywania zmiennych.
										|Identyfikator nie może zawierać spacji i znaków specjalnych i nie może zaczynać się od cyfry.';
										|tr = 'Tanımlayıcı, değişiklikleri adlandırma kurallarıyla eşleşmiyor.
										|Tanımlayıcı boşluklar ve özel semboller içermemelidir ve rakamlarla başlamamalıdır.'");
			Common.MessageToUser(
				StringFunctionsClientServer.SubstituteParametersToString(MessageText, Id),
				ThisObject,
				"Id",, Cancel);
			IDVariable = False;
		EndIf;
		
		If IDVariable Then
			ReservedVariables = BudgetReportingClientServer.BudgetReportVariables();
			If ReservedVariables.Property(Id) Then
				MessageText = NStr("vi = 'Mã số định danh chỉ số không khớp với giá trị cho tham số ""%1"".';
									|ru = 'Идентификатор аналитики не может совпадать со значением параметра ""%1"".';
									|en = 'Dimension ID cannot match the value of the ""%1"" parameter.'; fa = 'Dimension ID cannot match the value of the ""%1"" parameter.';
									|it = 'L''identificatore dell''analitica non può coincidere con il valore del parametro ""%1';
									|pl = 'Identyfikator analityki nie może pokrywać się z wartością parametru ""%1"".';
									|tr = 'Boyut kimliği ""%1"" parametre değeriyle çakışamaz.'");
				Common.MessageToUser(
					StringFunctionsClientServer.SubstituteParametersToString(
						MessageText,
						Id),
					ThisObject, "Id",, Cancel);

			Else
				Query = New Query;
				Query.Text = "SELECT TOP 1
					|	BudgetFlowItemDimensions.Ref
					|FROM
					|	ChartOfCharacteristicTypes.BudgetFlowItemDimensions AS BudgetFlowItemDimensions
					|WHERE
					|	BudgetFlowItemDimensions.Ref <> &Ref
					|	AND BudgetFlowItemDimensions.Id = &Id";
				Query.SetParameter("Ref", Ref);
				Query.SetParameter("Id", Id);

				Result = Query.Execute();
				If Not Result.IsEmpty() Then
					MessageText = NStr("vi = 'Cơ sở dữ liệu đã chứa dạng chỉ số với mã định danh ""%1"". ID phải là duy nhất';
										|ru = 'В базе данных уже содержится вид аналитики с идентификатором ""%1"". Идентификатор должен быть уникальным';
										|en = 'Dimension kind with ID ""%1"" already exists in the infobase. The ID should be unique'; fa = 'Dimension kind with ID ""%1"" already exists in the infobase. The ID should be unique';
										|it = 'Nel database esiste già un tipo di prezzo con l''identificatore ""%%1"". L''identificatore deve essere univoco';
										|pl = 'W bazie danych istnieje już rodzaj analityki z identyfikatorem ""%1"". Identyfikator powinien być unikalny';
										|tr = 'Veri tabanı halihazırda ""%1"" tanımlayıcısıyla boyut türünü içerir. Tanımlayıcı benzersiz olmalıdır'");
					Common.MessageToUser(
						StringFunctionsClientServer.SubstituteParametersToString(
							MessageText,
							Id),
						ThisObject, "Id",, Cancel);
				EndIf;
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf