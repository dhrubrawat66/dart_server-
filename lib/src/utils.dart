import 'package:shelf/shelf.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

Middleware handleCors() {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'GET, POST, PUT, DELETE',
    'Acess-Control-Allow-Headers': 'Origin, Content-Type',
  };

  return createMiddleware(requestHandler: (Request request) {
    if (request.method == 'OPTIONS') {
      return Response.ok('', headers: corsHeaders);
    }
    return null;
  }, responseHandler: (Response response) {
    return response.change(headers: corsHeaders);
  });
}

String generateSalt([int length = 32]) {
  final rand = Random.secure();
  final saltBytes = List<int>.generate(length, (index) => rand.nextInt(256));
  return base64.encode(saltBytes);
}

String hashPassword(String password, String salt) {
  final codec = Utf8Codec();
  final key = codec.encode(password);
  final saltBytes = codec.encode(salt);
  final hmac = Hmac(sha256, key);
  final digest = hmac.convert(saltBytes);
  return digest.toString();
}

String geneerateJwt(String subject, String issuer, String secret) {
  final jwt = JWT({
    'iat': DateTime.now().microsecondsSinceEpoch,
  }, subject: subject, issuer: issuer);
  return jwt.sign(SecretKey(secret));
}

dynamic verifyJwt(String token, String secret) {
  try {
    final jwt = JWT.verify(token, SecretKey(secret));
    return jwt;
  } on JWTExpiredError {
    // TODO Handle error
  } on JWTError catch (err) {
    //TODO Handle error
  }
}

Middleware handleAuth(String secret) {
  return (Handler innerHandler) {
    return (Request request) async {
      final authHeader = request.headers['authorization'];
      var token, jwt;

      if (authHeader != null && authHeader.startsWith('Bearer ')) {
        token = authHeader.substring(7);
        jwt = verifyJwt(token, secret);
      }
      final updateRequest = request.change(context: {
        'authDetails': jwt,
      });
      return await innerHandler(updateRequest);
    };
  };
}

Middleware checkAuthorisation() {
  return createMiddleware(
    requestHandler: (Request request) {
      if (request.context['authDetails'] == null) {
        return Response.forbidden('Not authorized to perform this action.');
      }
      return null;
    },
  );
}

Handler fallback(String indexPath) => (Request request) {
      final indexFile = File(indexPath).readAsStringSync();
      return Response.ok(indexFile, headers: {'content-type': 'text/html'});
    };
