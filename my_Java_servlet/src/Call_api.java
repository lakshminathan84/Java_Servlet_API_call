

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class Call_api
 */
@WebServlet("/Call_api")
public class Call_api extends HttpServlet {
	private static final long serialVersionUID = 1L;
	

    /**
     * Default constructor. 
     */
    public Call_api() {
        // TODO Auto-generated constructor stub
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		// TODO Auto-generated method stub
		String code = request.getParameter("code");
		response.setContentType("text/html");
		PrintWriter out=response.getWriter();
		out.print("<html>"+code +"<body>");
		out.print("<h3>Hello lakshmi</h3>");
		out.print("</body></html>");
		response.getWriter().append("Served at: ").append(request.getContextPath());
	}

}
