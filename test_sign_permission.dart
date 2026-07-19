import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var loginUrl = Uri.parse('https://erp.chanhungltd.info.vn/api/v1/auth/login');
  var response = await http.post(loginUrl, body: {
    'email': 'quyenpv@gmail.com',
    'password': 'Xuanptt@2008'
  });
  
  if (response.statusCode != 200) {
    print('Login failed: ${response.statusCode} ${response.body}');
    return;
  }
  
  var data = jsonDecode(response.body);
  var token = data['data']['data']['token'];
  var tokenType = 'Bearer';
  
  print('Got token');
  
  // Checking PR ID 10
  var prId = 10;
  var detUrl = Uri.parse('https://erp.chanhungltd.info.vn/api/v1/payment_requests/$prId/sign-permission');
  var detRes = await http.get(detUrl, headers: {
    'Authorization': '$tokenType $token',
    'X-Auth-Token': token
  });
  
  print('Permission status: ${detRes.statusCode}');
  print('Permission body: ${detRes.body}');
}
